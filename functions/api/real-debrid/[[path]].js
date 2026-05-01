const allowedMethods = new Set(['GET', 'POST', 'OPTIONS']);

function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,POST,OPTIONS',
    'Access-Control-Allow-Headers': 'authorization,content-type',
    'Access-Control-Max-Age': '86400',
  };
}

export async function onRequest({ request, params }) {
  if (!allowedMethods.has(request.method)) {
    return new Response('Method not allowed', { status: 405 });
  }

  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  const path = Array.isArray(params.path)
    ? params.path.join('/')
    : params.path || '';
  const sourceUrl = new URL(request.url);
  const targetUrl = new URL(`https://api.real-debrid.com/${path}`);
  targetUrl.search = sourceUrl.search;

  const headers = new Headers(request.headers);
  headers.delete('host');
  headers.delete('connection');
  headers.delete('accept-encoding');
  headers.delete('origin');
  headers.delete('referer');

  try {
    const upstream = await fetch(targetUrl, {
      method: request.method,
      headers,
      body:
        request.method === 'GET' || request.method === 'HEAD'
          ? undefined
          : request.body,
    });
    const responseHeaders = new Headers(corsHeaders());
    responseHeaders.set(
      'Content-Type',
      upstream.headers.get('content-type') || 'application/json; charset=utf-8',
    );
    responseHeaders.set('Cache-Control', 'no-store');

    return new Response(upstream.body, {
      status: upstream.status,
      headers: responseHeaders,
    });
  } catch {
    return Response.json(
      {
        error:
          'StreamVault could not reach Real-Debrid through the Cloudflare proxy.',
      },
      { status: 502, headers: corsHeaders() },
    );
  }
}
