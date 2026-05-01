function corsHeaders() {
  return {
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET,OPTIONS',
    'Access-Control-Allow-Headers': 'content-type',
    'Access-Control-Max-Age': '86400',
  };
}

export async function onRequest({ request, params }) {
  if (request.method === 'OPTIONS') {
    return new Response(null, { status: 204, headers: corsHeaders() });
  }

  if (request.method !== 'GET') {
    return new Response('Method not allowed', { status: 405 });
  }

  const path = Array.isArray(params.path)
    ? params.path.join('/')
    : params.path || '';
  const sourceUrl = new URL(request.url);
  const targetUrl = new URL(`https://torrentio.strem.fun/${path}`);
  targetUrl.search = sourceUrl.search;

  try {
    const upstream = await fetch(targetUrl, {
      headers: { Accept: 'application/json' },
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
        streams: [],
        error:
          'StreamVault could not reach Torrentio through the Cloudflare proxy.',
      },
      { status: 502, headers: corsHeaders() },
    );
  }
}
