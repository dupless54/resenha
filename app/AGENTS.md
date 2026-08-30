# Resenha app layer

- Controllers/models/jobs derive current user and room/call/recording permissions server-side.
- Room membership/invite/role/call actions never trust client-owned identity or privilege fields.
- Reviewable/moderation behavior preserves staff authority and auditable state.
- Background jobs for LiveKit/recordings/status cleanup are bounded, retry-safe, and idempotent.
- User deletion cleanup must keep room ownership valid and remove user-specific roster/contact state according to current retention policy.
- Public/API serializers expose only the minimum room/call state authorized for the viewer.
