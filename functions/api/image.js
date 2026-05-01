const allowedHosts = new Set([
  'images.metahub.space',
  'static.metahub.space',
  'episodes.metahub.space',
]);

export async function onRequestGet(context) {
  const requestUrl = new URL(context.request.url);
  const rawUrl = requestUrl.searchParams.get('url') || '';
  let target;
  try {
    target = new URL(rawUrl);
  } catch {
    return new Response('Invalid image URL', { status: 400 });
  }

  if (target.protocol !== 'https:' || !allowedHosts.has(target.hostname)) {
    return new Response('Image host not allowed', { status: 403 });
  }

  const upstream = await fetch(target, {
    headers: { Accept: context.request.headers.get('accept') || 'image/*' },
  });

  if (!upstream.ok) {
    return new Response('Image unavailable', { status: upstream.status });
  }

  return new Response(upstream.body, {
    status: 200,
    headers: {
      'Content-Type': upstream.headers.get('content-type') || 'image/jpeg',
      'Cache-Control': 'public, max-age=86400',
      'Access-Control-Allow-Origin': '*',
    },
  });
}
