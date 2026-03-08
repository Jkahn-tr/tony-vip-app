# Blaze API Contracts
**Version:** v1  
**Base URL:** `https://blaze-api.supabase.co/functions/v1`  
**Auth:** `Authorization: Bearer <token>` on all requests  
**Content-Type:** `application/json`

---

## Endpoints

### 1. Send Message
`POST /messages/send`

Send a message from Tony to a contact via the Blaze channel.

**Request**
```json
{
  "contact_id": "uuid",
  "body": "string",
  "channel": "blaze | sms | email"
}
```

**Response `200`**
```json
{
  "id": "uuid",
  "contact_id": "uuid",
  "body": "string",
  "is_from_tony": true,
  "sent_at": "ISO8601",
  "channel": "blaze",
  "is_read": true
}
```

---

### 2. Fetch Contact Context
`GET /contacts/{id}/context`

Returns the AI-generated Blaze context card for a contact.

**Response `200`**
```json
{
  "summary": "string",
  "suggested_opener": "string | null",
  "key_facts": ["string"],
  "last_updated": "ISO8601"
}
```

---

### 3. Generate Suggested Opener
`POST /contacts/{id}/opener/generate`

Triggers a fresh Claude-generated opener based on latest interaction history.

**Request**
```json
{
  "hint": "string | null"
}
```

**Response `200`**
```json
{
  "opener": "string",
  "generated_at": "ISO8601"
}
```

---

### 4. Get Relationship Health
`GET /contacts/{id}/health`

Returns current relationship health score and decay metadata.

**Response `200`**
```json
{
  "contact_id": "uuid",
  "health": "Strong | Good | Fading | Cold",
  "score": 0.0,
  "days_since_contact": 34,
  "last_interaction_at": "ISO8601",
  "last_interaction_channel": "call | text | email | in_person",
  "alert_threshold_reached": false,
  "updated_at": "ISO8601"
}
```

---

### 5. Upsert Note
`PATCH /contacts/{id}/notes`

Create or update a note for a contact.

**Request**
```json
{
  "id": "uuid | null",
  "body": "string",
  "is_pinned": false
}
```

**Response `200`**
```json
{
  "id": "uuid",
  "contact_id": "uuid",
  "body": "string",
  "is_pinned": false,
  "created_at": "ISO8601"
}
```

---

## Supabase Schema

### `contacts`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | Apple Contacts mapped ID |
| `name` | text | |
| `role` | text | |
| `organization` | text | |
| `phone` | text | |
| `email` | text | |
| `tier` | text | Inner Circle / VIP / Key Contact |
| `tags` | text[] | |
| `avatar_color_hex` | text | |
| `created_at` | timestamptz | |
| `updated_at` | timestamptz | |

### `messages`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `contact_id` | uuid FK → contacts | |
| `body` | text | |
| `is_from_tony` | bool | |
| `sent_at` | timestamptz | |
| `channel` | text | blaze / sms / email |
| `is_read` | bool | |
| `bluebubbles_id` | text | BlueBubbles bridge ID |

### `relationship_health`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `contact_id` | uuid FK → contacts | |
| `health` | text | Strong / Good / Fading / Cold |
| `score` | float | 0.0 – 1.0 |
| `days_since_contact` | int | |
| `alert_threshold_reached` | bool | triggers APNs |
| `updated_at` | timestamptz | |

### `interaction_log`
| Column | Type | Notes |
|---|---|---|
| `id` | uuid PK | |
| `contact_id` | uuid FK → contacts | |
| `channel` | text | **call / text / email / in_person** |
| `duration_seconds` | int | null for text/email |
| `initiated_by` | text | **tony / contact** |
| `notes` | text | Optional context post-interaction |
| `occurred_at` | timestamptz | |
| `created_at` | timestamptz | |

*`interaction_log` is the primary feed for Claude context and the scoring engine. `channel` + `duration_seconds` + `initiated_by` are required for correct weighting.*

---

## Relationship Scoring Engine

### Time-Decay Formula
```
score = base_weight × initiated_multiplier × e^(-λ × days_since_contact)
```

### Interaction Weights
| Channel | Weight |
|---|---|
| In-person | 1.0 |
| Call (>15 min) | 0.9 |
| Call (<15 min) | 0.7 |
| Text / Blaze message | 0.4 |
| Email | 0.3 |
| Reaction / like | 0.1 |

**`initiated_by` = tony multiplier: 1.5×** — Tony reaching out signals stronger intent than receiving.  
**V2 — `sentiment_boost`:** Claude detects positive sentiment → +0.1 to weight. Not blocking for v1.

### Health Thresholds
| Score | Health | APNs Alert? |
|---|---|---|
| 0.75 – 1.0 | Strong | No |
| 0.50 – 0.74 | Good | No |
| 0.25 – 0.49 | Fading | Yes — soft nudge |
| 0.00 – 0.24 | Cold | Yes — urgent alert |

### Tier Decay Rates (λ)
| Tier | λ | Notes |
|---|---|---|
| Inner Circle | 0.02 | Slow decay — daily relationships |
| VIP | 0.04 | Standard decay |
| Key Contact | 0.07 | Higher touch threshold |

---

## Auth

**Phase 1:** Static service token from Supabase dashboard → stored in iOS Keychain (`BlazeKeychain`).  
**Phase 2:** Supabase Auth + Apple Sign-In → auto-refresh JWT tokens.  
For dev/testing: hardcode token in `BlazeKeychain.serviceToken`.

---

*Confirmed by Bartok — March 8, 2026. RealBlazeService wired.*
