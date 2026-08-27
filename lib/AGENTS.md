# Resenha library and LiveKit boundary

High-risk voice/security integration.

- Guardian extensions are authorization seams; client checks never replace them.
- LiveKit configuration/API secrets stay server-only.
- Issue room/access tokens only after current authorization; scope identity/room/permissions narrowly and keep expiry bounded.
- Treat LiveKit responses/webhooks/external state as untrusted until authenticated/validated.
- External network requests use safe URLs, TLS expectations, bounded connect/read/overall timeouts, and sanitized logs.
- Direct-call policy continues to honor mute, ignore, PM/privacy preferences, bot/self restrictions, and room availability.
- Hashtag data sources must filter inaccessible room data and preserve registered context priorities.
