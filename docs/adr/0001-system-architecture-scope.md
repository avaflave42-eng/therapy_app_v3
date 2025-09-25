# ADR 0001: System Architecture Scope

## Status
Proposed

## Context
We need a shared, stable place to reason about the system: domains, flows, and boundaries.
We also want Lovable to operate inside guardrails (docs/specs first; code second).

## Decision
Adopt an architecture spine:
- Docs-first in `docs/` (Mermaid + ADRs)
- Contracts in `spec/`
- Constrain Lovable to `app/**`, `docs/**`, `spec/**`
- Changes flow via Issue ➜ PR ➜ ADR (when architectural)

## Consequences
- Clear context for contributors and AI tools
- Easier review of system changes
- Slightly more ceremony

## Follow-ups
- ADR 0002: Domain boundaries & events
- ADR 0003: Data ownership & read models
