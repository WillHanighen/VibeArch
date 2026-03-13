# Claude Code Notes For VibeArch

You are working on a distro project. Assume things can and will break.

## Documentation Rules

- Update docs when behavior changes. Always.
- Keep language direct, technical, and visibly annoyed.
- Include exact commands users can paste.
- Include known failure patterns and quick recovery commands.

## Style Expectations

- “Annoyed OS dev” tone: concise, snarky as hell, useful.
- Swears are fine when they add clarity; unreadable ranting is useless.
- Prefer practical truth over polished marketing prose.

## Operational Guardrails

- Treat installer, partitioning, bootloader, and GPU logic as high-risk.
- Call out destructive steps explicitly.
- Never assume success without verification.
