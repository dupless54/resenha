# Mesh Small-Room Foundation — Implementation Plan

## Phase 1 — admission integrity

Use `resenha_mesh_max_participants` as a configurable site-wide mesh ceiling. Compute effective capacity as the minimum of the room limit and mesh ceiling. Enforce admission in the server-side participant tracker under a room-scoped `DistributedMutex`; existing participants may refresh without taking the mutex.

## Phase 2 — client UX

Consume serialized `effective_max_participants` and `full` state in existing sidebar and room-page surfaces. Use supported Discourse UI primitives, locale-backed copy, keyboard/touch-safe interactions, and standard Ajax error presentation. Client checks remain advisory; the server remains authoritative.

## Phase 3 — connection resilience

Add local-only connection-health observation with `RTCPeerConnection.getStats()`, then bounded ICE restart/reconnect handling for recoverable network changes. Do not upload private ICE candidate details or media telemetry by default.

## Validation

Run targeted model/service/request specs plus frontend QUnit/system coverage for changed UX, then require the official exact-head `Discourse Plugin` CI to be GREEN before merge.
