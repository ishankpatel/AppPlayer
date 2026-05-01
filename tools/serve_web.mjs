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

const realDebridPrefix = '/api/real-debrid';
const torrentioPrefix = '/api/torrentio';
const imageProxyPath = '/api/image';
const allowedImageHosts = new Set(['images.metahub.space', 'static.metahub.space']);

function collectBody(req) {
  return new Promise((resolve, reject) => {
    const chunks = [];
    req.on('data', (chunk) => chunks.push(chunk));
    req.on('end', () => resolve(Buffer.concat(chunks)));
    req.on('error', reject);
  });
}

async function proxyRealDebrid(req, res, rawPath) {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
      'Access-Control-Allow-Headers': 'authorization,content-type',
      'Access-Control-Max-Age': '86400',
    });
    res.end();
    return;
  }

  const requestUrl = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  const targetPath = rawPath.slice(realDebridPrefix.length) || '/';
  const target = new URL(`https://api.real-debrid.com${targetPath}`);
  target.search = requestUrl.search;

  const headers = { ...req.headers };
  delete headers.host;
  delete headers.connection;
  delete headers['accept-encoding'];
  delete headers.origin;
  delete headers.referer;

  try {
    const body =
      req.method === 'GET' || req.method === 'HEAD'
        ? undefined
        : await collectBody(req);
    const upstream = await fetch(target, {
      method: req.method,
      headers,
      body,
    });
    const buffer = Buffer.from(await upstream.arrayBuffer());
    res.writeHead(upstream.status, {
      'Content-Type':
        upstream.headers.get('content-type') || 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(buffer);
  } catch {
    res.writeHead(502, {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(
      JSON.stringify({
        error:
          'StreamVault could not reach Real-Debrid through the local web proxy.',
      }),
    );
  }
}

async function proxyTorrentio(req, res, rawPath) {
  if (req.method === 'OPTIONS') {
    res.writeHead(204, {
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET,OPTIONS',
      'Access-Control-Allow-Headers': 'content-type',
      'Access-Control-Max-Age': '86400',
    });
    res.end();
    return;
  }

  if (req.method !== 'GET') {
    res.writeHead(405, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Method not allowed');
    return;
  }

  const requestUrl = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  const targetPath = rawPath.slice(torrentioPrefix.length) || '/';
  const target = new URL(`https://torrentio.strem.fun${targetPath}`);
  target.search = requestUrl.search;

  try {
    const upstream = await fetch(target, {
      method: 'GET',
      headers: { Accept: 'application/json' },
    });
    const buffer = Buffer.from(await upstream.arrayBuffer());
    res.writeHead(upstream.status, {
      'Content-Type':
        upstream.headers.get('content-type') || 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(buffer);
  } catch {
    res.writeHead(502, {
      'Content-Type': 'application/json; charset=utf-8',
      'Cache-Control': 'no-store',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(
      JSON.stringify({
        streams: [],
        error: 'StreamVault could not reach Torrentio through the local web proxy.',
      }),
    );
  }
}

async function proxyImage(req, res) {
  if (req.method !== 'GET') {
    res.writeHead(405, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Method not allowed');
    return;
  }

  const requestUrl = new URL(req.url || '/', `http://${req.headers.host || 'localhost'}`);
  const rawUrl = requestUrl.searchParams.get('url') || '';
  let target;
  try {
    target = new URL(rawUrl);
  } catch {
    res.writeHead(400, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Invalid image URL');
    return;
  }

  if (target.protocol !== 'https:' || !allowedImageHosts.has(target.hostname)) {
    res.writeHead(403, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Image host not allowed');
    return;
  }

  try {
    const upstream = await fetch(target, {
      method: 'GET',
      headers: { Accept: req.headers.accept || 'image/*' },
    });
    if (!upstream.ok) {
      res.writeHead(upstream.status, { 'Content-Type': 'text/plain; charset=utf-8' });
      res.end('Image unavailable');
      return;
    }
    const buffer = Buffer.from(await upstream.arrayBuffer());
    res.writeHead(200, {
      'Content-Type': upstream.headers.get('content-type') || 'image/jpeg',
      'Cache-Control': 'public, max-age=86400',
      'Access-Control-Allow-Origin': '*',
    });
    res.end(buffer);
  } catch {
    res.writeHead(502, { 'Content-Type': 'text/plain; charset=utf-8' });
    res.end('Image proxy failed');
  }
}

function send(res, file) {
  const ext = path.extname(file).toLowerCase();
  const base = path.basename(file);
  const cacheControl =
    base === 'index.html' ||
    base === 'main.dart.js' ||
    base === 'flutter_service_worker.js' ||
    base === 'flutter_bootstrap.js'
      ? 'no-cache'
      : 'public, max-age=3600';
  res.writeHead(200, {
    'Content-Type': types.get(ext) || 'application/octet-stream',
    'Cache-Control': cacheControl,
  });
  fs.createReadStream(file).pipe(res);
}

function sendRetiredServiceWorker(res) {
  res.writeHead(200, {
    'Content-Type': 'application/javascript; charset=utf-8',
    'Cache-Control': 'no-store',
    'Clear-Site-Data': '"cache"',
  });
  res.end(`
self.addEventListener('install', (event) => self.skipWaiting());
self.addEventListener('activate', (event) => {
  event.waitUntil((async () => {
    const keys = await caches.keys();
    await Promise.all(keys.map((key) => caches.delete(key)));
    await self.registration.unregister();
    const clients = await self.clients.matchAll({ type: 'window' });
    for (const client of clients) client.navigate(client.url);
  })());
});
`);
}

http
  .createServer(async (req, res) => {
    const rawPath = decodeURIComponent((req.url || '/').split('?')[0]);
    if (rawPath === '/flutter_service_worker.js') {
      sendRetiredServiceWorker(res);
      return;
    }
    if (rawPath === imageProxyPath) {
      await proxyImage(req, res);
      return;
    }
    if (rawPath === realDebridPrefix || rawPath.startsWith(`${realDebridPrefix}/`)) {
      await proxyRealDebrid(req, res, rawPath);
      return;
    }
    if (rawPath === torrentioPrefix || rawPath.startsWith(`${torrentioPrefix}/`)) {
      await proxyTorrentio(req, res, rawPath);
      return;
    }

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
