# Resenha tests

- Prefer real authorization/policy paths for rooms, membership, calls, recordings, and settings.
- Cover allowed/denied/nonparticipant/private cases and avoid tests that leak secrets into snapshots/logs.
- LiveKit seams may be stubbed at the external boundary, but token/identity/room scoping and error handling must be decisive.
- Include reconnect/retry/idempotency paths for jobs/callbacks where relevant.
- Hashtag/chat tests should assert inaccessible rooms are not exposed and priority/context rules remain intact.
- Never report runtime tests as passing if they did not execute.
