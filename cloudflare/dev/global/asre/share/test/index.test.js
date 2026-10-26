import { afterEach, describe, expect, it, vi } from "vitest";
import worker from "../src/index.js";

function environment() {
  const objects = new Map();
  return {
    env: {
      UPLOAD_TOKEN: "test-secret",
      MAX_UPLOAD_BYTES: "16",
      TTL_SECONDS: "60",
      SHARES: {
        async put(key, value, options) { objects.set(key, { value, customMetadata: options.customMetadata }); },
        async get(key) {
          const object = objects.get(key);
          return object && { text: async () => object.value, customMetadata: object.customMetadata };
        },
        async list() { return { objects: [], truncated: false }; },
        async delete(key) { objects.delete(key); },
      },
    },
    objects,
  };
}

function upload(env, content, options = {}) {
  return worker.fetch(new Request("https://share.example/api/share", {
    method: "POST",
    headers: {
      Authorization: options.auth ?? "Bearer test-secret",
      "Content-Type": options.type ?? "text/plain",
      "Content-Length": options.length ?? String(new TextEncoder().encode(content).length),
    },
    body: content,
  }), env);
}

afterEach(() => vi.restoreAllMocks());

describe("share worker", () => {
  it("requires bearer auth, media type, and bounded content", async () => {
    const { env } = environment();
    expect((await upload(env, "hi", { auth: "Bearer wrong" })).status).toBe(401);
    expect((await upload(env, "hi", { type: "application/json" })).status).toBe(415);
    expect((await upload(env, "a".repeat(17))).status).toBe(413);
  });

  it("returns a random capability URL and safely renders uploaded markup as text", async () => {
    const { env } = environment();
    env.MAX_UPLOAD_BYTES = "64";
    const uploaded = await upload(env, "<script>alert(1)</script>");
    expect(uploaded.status).toBe(201);
    const { url } = await uploaded.json();
    expect(url).toMatch(/^https:\/\/share\.example\/s\/[A-Za-z0-9_-]{43}$/);
    const page = await worker.fetch(new Request(url), env);
    expect(page.headers.get("Content-Security-Policy")).toContain("default-src 'none'");
    expect(await page.text()).toContain("&lt;script&gt;");
    expect(await page.text()).not.toContain("<script>");
    expect((await worker.fetch(new Request("https://share.example/s/nope"), env)).status).toBe(404);
  });

  it("rejects expired capability metadata", async () => {
    const { env } = environment();
    env.SHARES.get = async () => ({ text: async () => "gone", customMetadata: { expiresAt: "1" } });
    expect((await worker.fetch(new Request(`https://share.example/s/${"a".repeat(43)}`), env)).status).toBe(404);
  });

  it("rejects misleading declared length even before reading", async () => {
    const { env } = environment();
    const request = new Request("https://share.example/api/share", {
      method: "POST", headers: { Authorization: "Bearer test-secret", "Content-Type": "text/plain", "Content-Length": "17" }, body: "x",
    });
    expect((await worker.fetch(request, env)).status).toBe(413);
  });
});
