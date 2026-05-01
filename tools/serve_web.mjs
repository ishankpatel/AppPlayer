import http from 'node:http';
import fs from 'node:fs';
import path from 'node:path';

const root = process.env.STREAMVAULT_WEB_DIR;
const port = Number(process.env.STREAMVAULT_WEB_PORT || 8088);

if (!root || !fs.existsSync(root)) {
  console.error(`Missing web build directory: ${root ?? '(not set)'}`);
  process.exit(1);
}

const types = new Map([
  ['.html', 'text/html; charset=utf-8'],
  ['.js', 'application/javascript; charset=utf-8'],
  ['.css', 'text/css; charset=utf-8'],
  ['.json', 'application/json; charset=utf-8'],
  ['.png', 'image/png'],
  ['.jpg', 'image/jpeg'],
  ['.jpeg', 'image/jpeg'],
  ['.svg', 'image/svg+xml'],
  ['.ico', 'image/x-icon'],
  ['.wasm', 'application/wasm'],
]);

function send(res, file) {
  const ext = path.extname(file).toLowerCase();
  res.writeHead(200, {
    'Content-Type': types.get(ext) || 'application/octet-stream',
    'Cache-Control': file.endsWith('index.html')
      ? 'no-cache'
      : 'public, max-age=3600',
  });
  fs.createReadStream(file).pipe(res);
}

http
  .createServer((req, res) => {
    const rawPath = decodeURIComponent((req.url || '/').split('?')[0]);
    const safePath = path.normalize(rawPath).replace(/^(\.\.[/\\])+/, '');
    let file = path.join(root, safePath);

    if (rawPath.endsWith('/')) file = path.join(file, 'index.html');

    if (fs.existsSync(file) && fs.statSync(file).isFile()) {
      send(res, file);
      return;
    }

    send(res, path.join(root, 'index.html'));
  })
  .listen(port, '0.0.0.0');
