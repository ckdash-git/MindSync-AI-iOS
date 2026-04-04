# MindSync Sync Server — Architecture Research Plan

This document outlines the architecture for a self-hosted synchronisation backend that enables chat history to sync across iOS, Android, and web clients. No implementation is included here — this serves as the design reference for the future `feature/sync` iOS implementation and the Go server build.

---

## Goals

- Users' chat sessions and messages sync across all their devices automatically.
- Works on iOS, Android, and web from a single API.
- Self-hosted on a VPS to keep costs low and data under our control.
- No vendor lock-in — the server can be migrated to any provider in minutes.

---

## Stack

| Component | Choice | Rationale |
|-----------|--------|-----------|
| Language | Go 1.22+ | Single static binary, ~20 MB idle RAM, trivial cross-compile, excellent stdlib HTTP |
| Router | `chi` | Lightweight, middleware-composable, stdlib-compatible |
| Auth | JWT (RS256) | Stateless; works identically on mobile + web; `golang-jwt/jwt` library |
| Database | PostgreSQL 16 | ACID, JSON columns for flexible message payloads, mature driver (`pgx/v5`) |
| Migrations | `golang-migrate` | SQL-file migrations checked into source control |
| TLS / Reverse proxy | Caddy | Auto-provisioned Let's Encrypt certificates; zero-config HTTPS |
| Container orchestration | Docker Compose | Single `docker compose up -d` deploys everything |
| Hosting | Hetzner CX22 or Fly.io | See cost estimate below |

---

## API Design

All endpoints under `/api/v1`. Authentication via `Authorization: Bearer <jwt>` header.

### Auth

```
POST /api/v1/auth/register
  Body: { "email": string, "password": string }
  Response: { "token": string, "user_id": string }

POST /api/v1/auth/login
  Body: { "email": string, "password": string }
  Response: { "token": string, "user_id": string }

POST /api/v1/auth/refresh
  Body: { "refresh_token": string }
  Response: { "token": string }
```

### Sessions

```
GET  /api/v1/sessions
  Response: [ChatSession]                (sorted by updated_at desc)

POST /api/v1/sessions
  Body: ChatSession
  Response: ChatSession

PUT  /api/v1/sessions/:id
  Body: ChatSession (full replace)
  Response: ChatSession

DELETE /api/v1/sessions/:id
  Response: 204 No Content
```

### Messages

```
GET  /api/v1/sessions/:id/messages
  Response: [ChatMessage]               (sorted by timestamp asc)

POST /api/v1/sessions/:id/messages
  Body: ChatMessage
  Response: ChatMessage
```

---

## Database Schema

```sql
CREATE EXTENSION IF NOT EXISTS "pgcrypto";

CREATE TABLE users (
    id            UUID PRIMARY KEY DEFAULT gen_random_uuid(),
    email         TEXT UNIQUE NOT NULL,
    password_hash TEXT NOT NULL,
    created_at    TIMESTAMPTZ NOT NULL DEFAULT now()
);

CREATE TABLE sessions (
    id             UUID PRIMARY KEY,
    user_id        UUID NOT NULL REFERENCES users(id) ON DELETE CASCADE,
    title          TEXT NOT NULL DEFAULT 'New Chat',
    selected_model TEXT NOT NULL,
    created_at     TIMESTAMPTZ NOT NULL,
    updated_at     TIMESTAMPTZ NOT NULL
);

CREATE INDEX ON sessions(user_id, updated_at DESC);

CREATE TABLE messages (
    id          UUID PRIMARY KEY,
    session_id  UUID NOT NULL REFERENCES sessions(id) ON DELETE CASCADE,
    role        TEXT NOT NULL,          -- 'user' | 'assistant' | 'system'
    content     TEXT NOT NULL,
    provider    TEXT,                   -- 'openai' | 'anthropic' | 'gemini'
    model_id    TEXT,
    timestamp   TIMESTAMPTZ NOT NULL,
    is_streaming BOOLEAN NOT NULL DEFAULT FALSE
);

CREATE INDEX ON messages(session_id, timestamp ASC);
```

---

## Go Project Structure

```
mindsync-server/
├── cmd/server/main.go          # Entry point, wires dependencies
├── internal/
│   ├── auth/                   # JWT generation, validation, refresh
│   ├── handler/                # HTTP handlers (sessions, messages, auth)
│   ├── middleware/             # Auth middleware, request logger, recovery
│   ├── model/                  # Go structs mirroring DB schema
│   ├── repository/             # DB queries via pgx/v5
│   └── service/                # Business logic between handler and repository
├── migrations/
│   ├── 001_init.up.sql
│   └── 001_init.down.sql
├── docker-compose.yml
├── Caddyfile
└── Dockerfile
```

---

## Deployment

### docker-compose.yml (skeleton)

```yaml
services:
  server:
    build: .
    environment:
      - DATABASE_URL=postgres://mindsync:secret@db:5432/mindsync
      - JWT_PRIVATE_KEY_FILE=/run/secrets/jwt_private.pem
      - JWT_PUBLIC_KEY_FILE=/run/secrets/jwt_public.pem
    depends_on: [db]
    restart: unless-stopped

  db:
    image: postgres:16-alpine
    environment:
      POSTGRES_USER: mindsync
      POSTGRES_PASSWORD: secret
      POSTGRES_DB: mindsync
    volumes:
      - pgdata:/var/lib/postgresql/data
    restart: unless-stopped

  caddy:
    image: caddy:2-alpine
    ports: ["80:80", "443:443"]
    volumes:
      - ./Caddyfile:/etc/caddy/Caddyfile
      - caddy_data:/data
    restart: unless-stopped

volumes:
  pgdata:
  caddy_data:
```

### Caddyfile (skeleton)

```
sync.your-domain.com {
    reverse_proxy server:8080
}
```

---

## iOS Integration Plan (future `feature/sync` iOS implementation)

### New files

| File | Layer | Description |
|------|-------|-------------|
| `Domain/Repositories/SyncRepositoryProtocol.swift` | Domain | Protocol mirroring `ChatSessionRepositoryProtocol` but async-to-remote |
| `Data/Repositories/SyncChatRepository.swift` | Data | HTTP calls to Go server; wraps `NetworkManager` |
| `Domain/UseCases/AuthUseCase.swift` | Domain | Register, login, token refresh |
| `Presentation/Auth/` | Presentation | Sign-in / register screen |

### Write strategy

On every session save:
1. Always write locally (`ChatSessionLocalRepository`) for instant offline access.
2. If the user is signed in, also push to the Go server asynchronously via `SyncChatRepository`.
3. On app launch, fetch remote sessions and merge by `updatedAt` (latest wins).

This keeps the app fully functional without a network connection and syncs silently in the background.

### Conflict resolution

Last-write-wins by `updated_at` timestamp. No operational transform or CRDT needed at this scale — chat sessions are not collaboratively edited.

---

## Cost Estimate

| Provider | Spec | Estimated Cost |
|----------|------|----------------|
| **Hetzner CX22** | 2 vCPU / 4 GB RAM / 40 GB SSD / 20 TB traffic | ~€3.85/month |
| **Fly.io shared-cpu-1x** | 256 MB RAM (free tier) | Free up to limits |
| **Supabase** (managed Postgres) | 500 MB (free tier) | Free |
| Domain + DNS | - | ~$10–15/year |

**Minimum viable cost: €0–4/month** for early-stage with < 1 000 users.

Hetzner CX22 + self-managed Postgres is the recommended path once the user base grows — it gives full control and predictable pricing.

---

## Security Considerations

- Passwords hashed with `bcrypt` (cost factor 12).
- JWTs signed with RS256 (asymmetric); private key stored as a Docker secret, never in env vars.
- All traffic over TLS (Caddy handles certificate rotation automatically).
- API keys (OpenAI / Anthropic / Gemini) are **never** sent to or stored on the sync server — they remain exclusively in the iOS Keychain.
- Rate-limit auth endpoints (`/auth/register`, `/auth/login`) via middleware.
- PostgreSQL not exposed to the public internet — only accessible within the Docker internal network.
