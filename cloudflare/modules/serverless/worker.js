export default {
  async fetch(request, env) {
    if (request.method !== "GET" || new URL(request.url).pathname !== "/health") {
      return new Response("Not found", { status: 404 });
    }

    try {
      const result = await env.DB.prepare("SELECT 1 AS ok").first();
      await env.KV.get("health");
      return Response.json({ ok: result?.ok === 1 });
    } catch {
      return Response.json({ ok: false }, { status: 503 });
    }
  },
};
