import './style.css';

await import(/* @vite-ignore */ `${import.meta.env.BASE_URL}runtime-config.js`);
await import('./runtime-config');
