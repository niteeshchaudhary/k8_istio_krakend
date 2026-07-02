# KrakenD EE: SockJS WebSocket routing (`/ws/*`)

This note explains why `configmap.yaml` defines **GET and POST** endpoints for SockJS paths, and why they use plain HTTP proxying instead of KrakenD EE's native `websocket` namespace.

## Context

The DebateApp backend exposes STOMP over **Spring SockJS**, not a plain WebSocket endpoint:

```java
registry.addEndpoint("/ws")
        .setAllowedOriginPatterns("*")
        .withSockJS();
```

The frontend connects with `sockjs-client` + `@stomp/stompjs`. Traffic reaches the backend through:

`browser → nginx (/125) → Istio → KrakenD EE → Spring backend`

Relevant KrakenD routes in `configmap.yaml`:

| Route | Method | Purpose |
| :--- | :--- | :--- |
| `/ws/info` | `GET` | SockJS handshake: client discovers supported transports |
| `/ws/{server}/{session}/{transport}` | `GET` | WebSocket upgrade, EventSource, and other GET-based transports |
| `/ws/{server}/{session}/{transport}` | `POST` | XHR-based transports (`xhr_send`, `xhr_streaming`, etc.) |

All three use `output_encoding: "no-op"` and `input_headers: ["*"]` so KrakenD acts as a transparent HTTP reverse proxy.

## Why GET and POST on the same path

SockJS is a **hybrid HTTP + WebSocket protocol**. A single client session generates multiple requests on dynamic paths, for example:

- `GET  /ws/info`
- `GET  /ws/abc/123/websocket` — WebSocket upgrade attempt
- `POST /ws/abc/123/xhr_send` — send a message over XHR fallback
- `POST /ws/abc/123/xhr_streaming` — receive streamed data over XHR fallback

The `{transport}` segment is the transport name (`websocket`, `xhr_send`, `xhr_streaming`, etc.). Different transports use different HTTP methods.

KrakenD EE requires **one endpoint object per HTTP method**. There is no `method: "*"` shortcut. From the [EE endpoint docs](https://www.krakend.io/docs/enterprise/endpoints/):

> If you need to support multiple methods (e.g., GET, POST) in the same endpoint, you must declare one endpoint object for each method.

| Config | Result |
| :--- | :--- |
| GET only | SockJS POST fallbacks get **405** at KrakenD |
| POST only | `/ws/info` and WebSocket upgrade GET calls fail |
| GET + POST | Full SockJS HTTP surface is covered |

## Why not use KrakenD EE `extra_config.websocket`

KrakenD EE provides a native WebSocket module for **pure RFC-6455** endpoints. It is configured separately from HTTP:

```json
{
  "endpoint": "/ws",
  "method": "GET",
  "extra_config": {
    "websocket": {
      "enable_direct_communication": true
    }
  },
  "backend": [{
    "host": ["ws://backend.backend:8093"],
    "url_pattern": "/ws"
  }]
}
```

That pattern fits a **fixed, single WebSocket path**. It does **not** fit SockJS because:

1. **EE manages HTTP and WebSocket traffic separately** — SockJS mixes both on related dynamic paths under `/ws/{server}/{session}/{transport}`.
2. **SockJS POST transports** (`xhr_send`, `xhr_streaming`) are regular HTTP requests, not WebSocket frames. The `websocket` namespace would not handle them.
3. **EE WebSocket multiplexing** shares one backend channel across clients — incompatible with per-session SockJS semantics.
4. **Dynamic path segments** (`{server}`, `{session}`, `{transport}`) do not map cleanly to a single `ws://` backend endpoint.

KrakenD EE documents a similar constraint for Socket.IO (another hybrid protocol): force `websocket`-only transport and use a dedicated `websocket` config. SockJS has the same class of problem, so we proxy it as **HTTP pass-through** instead.

See: [KrakenD EE WebSockets](https://www.krakend.io/docs/enterprise/websockets/)

## Why it works

With `no-op` encoding and permissive header/query forwarding, KrakenD EE proxies the SockJS sub-protocol transparently:

1. **WebSocket upgrade** — `GET .../websocket` with `Upgrade: websocket` passes through the HTTP proxy path.
2. **XHR fallbacks** — `POST` transports are proxied when WebSocket is unavailable or blocked.
3. **Backend security** — Spring Security permits `/ws/**` without JWT on every SockJS sub-request (session management handles WebSocket auth separately).

If connections succeed in the cluster, either the WebSocket upgrade is working end-to-end, or SockJS is falling back to XHR (POST) — both are explicitly covered by the GET + POST route definitions.

## When to use EE `websocket` instead

Use `extra_config.websocket` when the backend exposes a **native WebSocket** at a stable path (no SockJS, no Socket.IO). Examples: a custom chat gateway, IoT stream, or any RFC-6455 endpoint.

Keep the current GET + POST HTTP proxy pattern when the backend uses **SockJS** or any protocol that combines HTTP handshakes with optional WebSocket upgrade on dynamic paths.

## Related files

- `k8s/base/infra/krakend/configmap.yaml` — route definitions (`/ws/info`, `/ws/{server}/{session}/{transport}`)
- `DebateApp/backend/src/main/java/com/debateapp/config/WebSocketConfig.java` — Spring SockJS endpoint registration
- `DebateApp/frontend/src/pages/DebateRoom.jsx` — `SockJS` client connection
