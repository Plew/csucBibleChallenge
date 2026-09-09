# Single Sign-On (SSO) & Embedding Guide

This guide explains how to embed the **Bible Challenge** inside another application (such as Campus Hub, a web portal, or a mobile webview) and share user accounts seamlessly without double login.

---

## Architecture Overview

```
+-----------------------------+                  +----------------------------------+
|      Parent Application     |                  |       Bible Challenge App        |
|  (e.g., Campus Hub / PWA)   |                  |     (csucBibleChallenge)         |
+-----------------------------+                  +----------------------------------+
               |                                                   |
               |  1. Generates signed JWT                          |
               |     (email, name, exp, challenge_id)              |
               |                                                   |
               |  2. Loads iframe with SSO login URL:              |
               |     /auth/sso/login?token=<JWT>&embed=true        |
               +-------------------------------------------------->|
                                                                   | 3. Verifies HMAC-SHA256 signature
                                                                   | 4. Matches or auto-provisions user
                                                                   | 5. Enrolls in challenge (optional)
                                                                   | 6. Establishes session (SameSite: None)
                                                                   | 7. Redirects to /reading?embed=true
                                                                   |
               |  8. Challenge rendered in iframe (clean embed UI) |
               |<--------------------------------------------------+
```

---

## 1. Configuration & Secret Setup

Both applications must share the same secret key. In Bible Challenge, you can provide the secret in **either**:

1. **Rails Encrypted Credentials** (`config/credentials.yml.enc`):
   ```yaml
   sso:
     secret: your_generated_secret_key_here
   ```
2. **Environment Variable / `.env`**:
   ```bash
   EXTERNAL_SSO_SECRET=your_generated_secret_key_here
   ```

| Variable / Key | App | Default | Description |
|---|---|---|---|
| `EXTERNAL_SSO_SECRET` or `sso.secret` | Both | `test_sso_secret_key_12345` | Shared secret key for signing and verifying HS256 JWT tokens. |
| `SSO_FRAME_ANCESTORS` | Bible Challenge | `*` | Content-Security-Policy `frame-ancestors` directive (e.g. `*` or `https://campushub.org https://app.example.com`). |
| `SESSION_COOKIE_SAMESITE` | Bible Challenge | `none` (in prod) / `lax` (in dev) | Cookie `SameSite` policy. Must be `none` for cross-origin iframe session cookies. |

---

## 2. JWT Token Format

The parent app generates a standard **HS256 (HMAC-SHA256)** JSON Web Token.

### Payload Claims

```json
{
  "sub": "parent_user_12345",
  "email": "student@university.edu",
  "name": "Sarah Connor",
  "challenge_id": 9,
  "embed": true,
  "exp": 1757451600,
  "iat": 1757448000
}
```

| Field | Type | Required | Description |
|---|---|---|---|
| `email` | String | **Yes** | User's email. Used to look up existing accounts or auto-provision a new account. |
| `name` or `username` | String | No | User's display name. Used to generate a clean username if creating an account. |
| `sub` | String | No | Unique ID in the parent app. |
| `challenge_id` | Integer / String | No | Challenge ID to auto-enroll into and set as active challenge upon login. |
| `invitation_token` | String | No | Alternative: invitation token of a challenge to auto-join. |
| `embed` | Boolean | No | If `true`, enables embedded layout (hides site navbar and footer). |
| `return_to` | String | No | Relative path to land on after sign-in (e.g. `/reading`, `/challenges`). Defaults to `/reading`. |
| `exp` | Integer | **Recommended** | Unix timestamp expiration (e.g. 5–60 minutes from issue). |
| `iat` | Integer | No | Unix timestamp of issuance. |

---

## 3. Parent App Token Generation Examples

### TypeScript / Node.js / Next.js (using `jsonwebtoken` or `jose`)

```typescript
import jwt from "jsonwebtoken";

const SSO_SECRET = process.env.EXTERNAL_SSO_SECRET || "test_sso_secret_key_12345";
const BIBLE_CHALLENGE_URL = process.env.BIBLE_CHALLENGE_URL || "https://biblechallenge.app";

export function generateBibleChallengeSsoUrl(user: {
  id: string;
  email: string;
  name: string;
}, challengeId?: number): string {
  const payload = {
    sub: user.id,
    email: user.email,
    name: user.name,
    challenge_id: challengeId,
    embed: true,
    iat: Math.floor(Date.now() / 1000),
    exp: Math.floor(Date.now() / 1000) + (15 * 60) // 15-minute validity
  };

  const token = jwt.sign(payload, SSO_SECRET, { algorithm: "HS256" });

  return `${BIBLE_CHALLENGE_URL}/auth/sso/login?token=${encodeURIComponent(token)}&embed=true`;
}
```

### Python (using `PyJWT`)

```python
import time
import jwt
import urllib.parse

SSO_SECRET = "test_sso_secret_key_12345"
BIBLE_CHALLENGE_URL = "https://biblechallenge.app"

def get_bible_challenge_sso_url(user, challenge_id=None):
    now = int(time.time())
    payload = {
        "sub": str(user.id),
        "email": user.email,
        "name": getattr(user, "name", user.email.split("@")[0]),
        "challenge_id": challenge_id,
        "embed": True,
        "iat": now,
        "exp": now + 900  # 15 minutes
    }
    token = jwt.encode(payload, SSO_SECRET, algorithm="HS256")
    return f"{BIBLE_CHALLENGE_URL}/auth/sso/login?token={urllib.parse.quote(token)}&embed=true"
```

### Ruby (without external gem dependency)

```ruby
require "openssl"
require "base64"
require "json"

def generate_bible_challenge_sso_url(user, challenge_id: nil, secret: ENV["EXTERNAL_SSO_SECRET"])
  payload = {
    sub: user.id.to_s,
    email: user.email,
    name: user.name,
    challenge_id: challenge_id,
    embed: true,
    iat: Time.current.to_i,
    exp: (Time.current + 15.minutes).to_i
  }

  header = Base64.urlsafe_encode64({ alg: "HS256", typ: "JWT" }.to_json, padding: false)
  body = Base64.urlsafe_encode64(payload.to_json, padding: false)
  sig = Base64.urlsafe_encode64(OpenSSL::HMAC.digest("sha256", secret, "#{header}.#{body}"), padding: false)
  token = "#{header}.#{body}.#{sig}"

  "https://biblechallenge.app/auth/sso/login?token=#{token}&embed=true"
end
```

---

## 4. Embedding the Challenge in an `<iframe>`

In your parent application template or React/Vue component:

```html
<iframe
  src="<%= bible_challenge_sso_url %>"
  title="Daily Bible Challenge"
  style="width: 100%; height: 85vh; border: none; border-radius: 12px; overflow: hidden;"
  allow="clipboard-write"
  loading="lazy"
></iframe>
```

### In React / Next.js:

```tsx
export function BibleChallengeEmbed({ ssoUrl }: { ssoUrl: string }) {
  return (
    <div className="w-full h-full min-h-[600px] flex flex-col rounded-xl overflow-hidden shadow-sm">
      <iframe
        src={ssoUrl}
        title="Bible Challenge"
        className="w-full flex-1 border-0"
        allow="clipboard-write"
      />
    </div>
  );
}
```

---

## 5. Embedded Mode Features (`embed=true`)

When loaded with `embed=true`:
- The Bible Challenge **top navigation bar** (logo, theme toggle, profile menu) is hidden.
- The **footer** is hidden.
- PWA install prompts are suppressed.
- The reading content and bottom navigation (Reading, Groups, Stats) remain accessible and optimized for container sizing.
- The `is-embedded` CSS class is attached to `<body>` for custom styling.

---

## 6. Outbound SSO (Bible Challenge -> Parent App)

If a user signs into Bible Challenge directly and wants to link to Campus Hub / Parent App:
1. User visits `/auth/sso?return_to=https://parentapp.com/api/sso/callback`.
2. Bible Challenge verifies user session, signs an HS256 JWT, and redirects:
   `https://parentapp.com/api/sso/callback?token=<JWT>`
3. Parent app validates the token with `EXTERNAL_SSO_SECRET` and logs the user in.

---

## 7. Multi-Instance 1-Click Campus Pairing (For Open-Source Campus Hub PWAs)

When multiple universities/clubs deploy their own localized Campus Hub PWA instances, each instance can automatically pair with `andgodsaid.org` with a single click. No manual server secret configuration is required!

### 1-Click Pairing Sequence

```
+--------------------------+                               +-------------------------------+
|  Campus Hub Instance     |                               |   andgodsaid.org              |
|  (e.g., uc-campushub.org)|                               |   (csucBibleChallenge)        |
+--------------------------+                               +-------------------------------+
              |                                                            |
              | 1. Officer clicks "Connect Bible Challenge"                |
              |    Generates random `secret` & `nonce`                     |
              |    Redirects officer to:                                   |
              |    /campus/pair?campus_name=...&hub_url=...                |
              |                 &secret=...&nonce=...&callback_url=...     |
              +----------------------------------------------------------->|
                                                                           | 2. Officer signs in
                                                                           | 3. Officer chooses reading challenge
                                                                           | 4. Saves CampusConnection
                                                                           |
              | 5. 302 Redirect to callback_url:                           |
              |    ?status=success&challenge_id=9&challenge_name=...       |
              |<-----------------------------------------------------------+
              |
              | 6. Campus Hub stores secret & challenge_id. Done!
```

### Pairing Parameters (Sent to `/campus/pair`)

| Parameter | Description | Example |
|---|---|---|
| `campus_name` | Human-readable name of the university or club | `"Christian Students at UC"` |
| `hub_url` | Base URL of this Campus Hub instance | `"https://uc-campushub.org"` |
| `secret` | Cryptographically random secret generated by Campus Hub | `"hex_or_uuid_string"` |
| `nonce` | Random CSRF nonce string for pairing state verification | `"random_nonce_123"` |
| `callback_url` | Full URL on Campus Hub to receive the pairing response | `"https://uc-campushub.org/api/sso/callback"` |

### Callback Response (Sent to `callback_url`)

```text
https://uc-campushub.org/api/sso/callback?status=success&challenge_id=9&challenge_name=New+Testament+2026&nonce=random_nonce_123
```

### Inbound SSO Verification for Paired Campuses
When embedding the iframe for students, include `campus_url` (or `hub_url`) in the JWT payload:

```json
{
  "sub": "student_123",
  "email": "student@uc.edu",
  "name": "Sarah Connor",
  "campus_url": "https://uc-campushub.org",
  "embed": true,
  "exp": 1757451600
}
```

Bible Challenge will:
1. Look up the `CampusConnection` for `https://uc-campushub.org`.
2. Verify the HS256 signature using that campus's unique `sso_secret`.
3. Auto-enroll the student directly into the campus's selected challenge!

