# frozen_string_literal: true

require 'json'
require 'open3'
require 'rbconfig'
require 'tmpdir'

# rubocop:disable RSpec/DescribeClass, RSpec/ExampleLength
RSpec.describe 'ssbase init' do
  let(:cli) { File.expand_path('../bin/ssbase', __dir__) }

  def run_init(directory, *args)
    Open3.capture3(
      {'RUBYOPT' => nil},
      RbConfig.ruby,
      cli,
      'init',
      *args,
      chdir: directory
    )
  end

  def generated_files(directory)
    Dir.glob("#{directory}/**/{*,.*}", File::FNM_DOTMATCH)
      .select { File.file?(_1) }
      .map { _1.delete_prefix("#{directory}/") }
  end

  def unresolved_service_names(directory)
    generated_files(directory).select do |relative_path|
      File.binread(File.join(directory, relative_path)).include?('${service_name}')
    end
  end

  def run_runtime_settings(path_prefix)
    script = File.expand_path(
      '../lib/stack-service-base/frontend_template/home/docker/frontend/15-runtime-settings.envsh',
      __dir__
    )
    command = <<~'SH'
      . "$1"
      printf 'prefix=%s\nresolver=%s\nproto=%s\nhost=%s\nport=%s\nrule=%s\n' \
        "$PATH_PREFIX" "$DNS_RESOLVER" "$BACKEND_PROTO" "$BACKEND_HOST" "$BACKEND_PORT" "$PATH_PREFIX_RULE"
    SH

    Open3.capture3(
      {
        'PATH_PREFIX' => path_prefix,
        'DNS_RESOLVER' => '127.0.0.1',
        'BACKEND_URL' => 'https://api.example.com:8443'
      },
      'sh', '-c', command, 'runtime-settings', script
    )
  end

  it 'generates a GitLab C frontend service by default' do
    Dir.mktmpdir do |directory|
      stdout, stderr, status = run_init(directory, '--frontend', 'frontend-service')
      package = JSON.parse(File.read(File.join(directory, 'src/package.json')))
      package_lock = JSON.parse(File.read(File.join(directory, 'src/package-lock.json')))
      index = File.read(File.join(directory, 'src/index.html'))
      dockerfile = File.read(File.join(directory, 'docker/frontend/Dockerfile'))
      compose = File.read(File.join(directory, 'docker/docker-compose.yml'))
      nginx = File.read(File.join(directory, 'docker/frontend/nginx.conf.template'))

      aggregate_failures do
        expect(status.success?).to be(true), -> { "stderr: #{stderr}\nstdout: #{stdout}" }
        expect(stderr).to eq('')
        expect(stdout).to include('Copy template: home', 'Copy template: gitlab-c')
        expect(package.fetch('name')).to eq('frontend-service')
        expect(package_lock.dig('packages', '', 'name')).to eq('frontend-service')
        expect(package.dig('engines', 'node')).to eq('^24.18.0')
        expect(package.fetch('scripts')).to include(
          'test' => 'vitest run',
          'preview' => 'npm run build:preview && vite preview --host 0.0.0.0 --mode preview'
        )
        expect(generated_files(directory)).to include(
          '.gitlab-ci.yml',
          'docker/Dockerfile.build',
          'docker/docker-compose.yml',
          'docker/frontend/Dockerfile',
          'src/app/main.ts',
          'src/public/runtime-config.js',
          'src/tests/build-proxy.test.ts',
          'src/tests/javascript-support.test.js',
          'src/tests/path-prefix.test.ts',
          'src/tests/runtime-config.test.ts',
          'src/tests/vite-config.test.ts'
        )
        expect(generated_files(directory)).not_to include('src/Gemfile', 'src/config.ru')
        expect(generated_files(directory)).not_to include('src/tools/vite/ci-build.ts')
        expect(index).not_to include('Path prefix', 'API base URL', 'Log level', 'build-info')
        expect(dockerfile).to include(
          'nginxinc/nginx-unprivileged:1.28.1-alpine',
          'USER 101:101',
          'EXPOSE 8080'
        )
        expect(compose).to include('"7000:8080"')
        expect(nginx).to include('Content-Security-Policy')
        expect(unresolved_service_names(directory)).to be_empty
      end
    end
  end

  {
    '--gitlab' => '.gitlab-ci.yml',
    '--github' => '.github/workflows/main.yml'
  }.each do |platform, ci_file|
    it "generates the frontend #{platform} overlay" do
      Dir.mktmpdir do |directory|
        stdout, stderr, status = run_init(directory, '--frontend', platform, 'frontend-service')
        ci = File.read(File.join(directory, ci_file))

        aggregate_failures do
          expect(status.success?).to be(true), -> { "stderr: #{stderr}\nstdout: #{stdout}" }
          expect(stderr).to eq('')
          expect(generated_files(directory)).to include(ci_file, 'docker/docker-compose.yml')
          if platform == '--github'
            expect(ci).to include(
              'actions/setup-node@v4',
              'npm ci',
              'npm run check',
              '--full-version',
              'github set_version to_dockerfiles to_compose'
            )
          end
          expect(unresolved_service_names(directory)).to be_empty
        end
      end
    end
  end

  it 'keeps the Ruby service as the default template' do
    Dir.mktmpdir do |directory|
      stdout, stderr, status = run_init(directory, '--gitlab-c', 'ruby-service')

      aggregate_failures do
        expect(status.success?).to be(true), -> { "stderr: #{stderr}\nstdout: #{stdout}" }
        expect(stderr).to eq('')
        expect(generated_files(directory)).to include(
          '.gitlab-ci.yml',
          'docker/ruby/Dockerfile',
          'src/Gemfile',
          'src/config.ru'
        )
        expect(generated_files(directory)).not_to include('src/package.json')
      end
    end
  end

  it 'does not overwrite existing files' do
    Dir.mktmpdir do |directory|
      readme = File.join(directory, 'README.md')
      File.write(readme, "Existing README\n")

      _stdout, stderr, status = run_init(directory, '--frontend', 'frontend-service')

      aggregate_failures do
        expect(status.success?).to be(true)
        expect(stderr).to eq('')
        expect(File.read(readme)).to eq("Existing README\n")
        expect(File).to exist(File.join(directory, 'src/package.json'))
      end
    end
  end

  it 'normalizes runtime settings and rejects reserved path prefixes' do
    stdout, stderr, status = run_runtime_settings('/team/ui/')

    aggregate_failures do
      expect(status.success?).to be(true), stderr
      expect(stderr).to eq('')
      expect(stdout).to include(
        "prefix=/team/ui\n",
        "resolver=127.0.0.1\n",
        "proto=https\n",
        "host=api.example.com\n",
        "port=8443\n",
        'location = /team/ui'
      )

      %w[api assets healthcheck].each do |path_prefix|
        _stdout, invalid_stderr, invalid_status = run_runtime_settings(path_prefix)

        expect(invalid_status.success?).to be(false)
        expect(invalid_stderr).to include('PATH_PREFIX is reserved')
      end
    end
  end

  it 'reuses the Ruby GitLab CI orchestration for frontend services' do
    %w[--gitlab-c --gitlab].each do |platform|
      Dir.mktmpdir do |frontend_directory|
        Dir.mktmpdir do |ruby_directory|
          _stdout, frontend_stderr, frontend_status = run_init(
            frontend_directory,
            '--frontend',
            platform,
            'shared-ci-service'
          )
          _stdout, ruby_stderr, ruby_status = run_init(
            ruby_directory,
            platform,
            'shared-ci-service'
          )

          aggregate_failures platform do
            expect(frontend_status.success?).to be(true), frontend_stderr
            expect(ruby_status.success?).to be(true), ruby_stderr

            shared_files = %w[.gitlab-ci.yml docker/local_build.sh]
            shared_files << 'docker/Dockerfile.build' if platform == '--gitlab'

            shared_files.each do |relative_path|
              expect(File.binread(File.join(frontend_directory, relative_path))).to eq(
                File.binread(File.join(ruby_directory, relative_path))
              )
            end

            if platform == '--gitlab-c'
              wrapper = File.read(File.join(frontend_directory, 'docker/Dockerfile.build'))
              expect(wrapper).to include(
                'FROM ruby:3.4.4-slim-bookworm',
                'gem install build-labels:0.0.79',
                'COMPOSE_VERSION=v2.33.0',
                'docker compose -f bake.yml'
              )
            end
          end
        end
      end
    end
  end

  it 'packages the frontend template files with the gem' do
    gemspec = Gem::Specification.load(File.expand_path('../gem.gemspec', __dir__))

    expect(gemspec.files).to include(
      'lib/stack-service-base/frontend_template/home/.gitignore',
      'lib/stack-service-base/frontend_template/home/src/.env.example',
      'lib/stack-service-base/frontend_template/home/src/package-lock.json',
      'lib/stack-service-base/frontend_template/home/src/tests/javascript-support.test.js',
      'lib/stack-service-base/frontend_template/home/src/tests/path-prefix.test.ts',
      'lib/stack-service-base/frontend_template/github/.github/workflows/main.yml'
    )
  end
end
# rubocop:enable RSpec/DescribeClass, RSpec/ExampleLength
