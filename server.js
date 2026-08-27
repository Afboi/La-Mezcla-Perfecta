// Minimal Bun server: static files + POST /api/event + SSE /events
const encoder = new TextEncoder();
const clients = new Set();

function contentTypeFor(path) {
  if (path.endsWith('.html')) return 'text/html; charset=utf-8';
  if (path.endsWith('.js')) return 'application/javascript; charset=utf-8';
  if (path.endsWith('.css')) return 'text/css; charset=utf-8';
  if (path.endsWith('.json')) return 'application/json; charset=utf-8';
  if (path.endsWith('.png')) return 'image/png';
  if (path.endsWith('.jpg') || path.endsWith('.jpeg')) return 'image/jpeg';
  return 'text/plain; charset=utf-8';
}

async function serveStatic(pathname) {
  const filePath = '.' + (pathname === '/' ? '/index.html' : pathname);
  const f = Bun.file(filePath);
  if (!(await f.exists())) return new Response('Not found', { status: 404 });
  // Serve the BunFile directly (streams raw bytes) instead of f.text(),
  // which decodes as UTF-8 and corrupts binary files like PNG/JPG.
  return new Response(f, { headers: { 'Content-Type': contentTypeFor(filePath) } });
}

Bun.serve({
  port: Number(process.env.PORT || 3000),
  async fetch(req) {
    const url = new URL(req.url);
    if (url.pathname === '/events') {
      const stream = new ReadableStream({
        start(controller) {
          clients.add(controller);
          // send a comment to establish the stream
          controller.enqueue(encoder.encode(': connected\n\n'));
        },
        cancel() {
          clients.delete(this);
        }
      });
      return new Response(stream, { headers: { 'Content-Type': 'text/event-stream', 'Cache-Control': 'no-cache', Connection: 'keep-alive' } });
    }

    if (url.pathname === '/api/event' && req.method === 'POST') {
      let data;
      try { data = await req.json(); } catch (e) { data = { error: 'invalid json' }; }
      const payload = `data: ${JSON.stringify(data)}\n\n`;
      const encoded = encoder.encode(payload);
      for (const c of [...clients]) {
        try { c.enqueue(encoded); } catch (e) { clients.delete(c); }
      }
      return new Response(JSON.stringify({ ok: true }), { headers: { 'Content-Type': 'application/json' } });
    }

    // serve static files (controller.html, view.html, ...) by path
    return serveStatic(url.pathname);
  }
});

console.log('Bun server running on port', process.env.PORT || 3000);
