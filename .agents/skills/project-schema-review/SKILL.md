---
name: project-schema-review
description: Review migrations, indexes, constraints, stored-data growth, and retention changes for correctness and production safety.
---
# Schema review
Check existing rows, room/membership/session/recording relationships, null/default/backfill, uniqueness/FKs/checks, indexes/query cadence, retention, lock/table-scan risk, rollback/recovery, and deploy ordering. Stop for irreversible/ambiguous data decisions; never execute destructive production operations.
