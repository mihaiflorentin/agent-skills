---
name: writing-specs
description: Writes or extends a design spec with the user: research brief, product questions first, provenance tags ([USER], [PROPOSED], [DEFAULT]) and a keep/cut pass on agent-proposed features. Use when a new product area needs a spec, or an existing spec needs new features, before any plan touches it.
disable-model-invocation: true
---

# Specs workflow

Copy this checklist and tick it off as you go:

```
Spec progress:
- [ ] 1. Research brief written
- [ ] 2. Product questions answered (or defaults logged)
- [ ] 3. Draft written
- [ ] 4. Every feature tagged [USER], [PROPOSED] or [DEFAULT]
- [ ] 5. Keep/cut pass on [PROPOSED] features done
- [ ] 6. Review done (broad specs only)
- [ ] 7. Writer passed its draft through unslop (if installed)
- [ ] 8. User approved; spec committed
```

Contents: Steps · Spec template · Why the flow looks like this

A spec says what the software must do and why. Plans argue from it, so an unexamined spec line turns into code. The most expensive spec defect is a **proposal posing as a decision**: a feature an agent invented that nobody ever put to the user. That is how daily quests got into a game whose owner never asked for them.

## Steps

1. **Research brief.** Dispatch a `scout`. It collects the source material (references, the existing code's behaviour, earlier specs), writes it to a scratch file, and returns its path plus a 10-line summary. Done when the brief names every area the spec must cover.
2. **Questions first.** Before anything is written, list the product questions. Each one gets 2–4 options, a recommendation with a one-line reason, and what it decides. Ask the user one decision at a time (AskUserQuestion), each with a Background paragraph that explains the terms in plain words, as `/orchestrating-development` sets out. Done when every question that would change the design has an answer, or a logged default if the user is away.
3. **Draft.** Dispatch one writer (`implementer-high`, or Opus for a broad design). Give it the brief, the answers verbatim and the template below. It writes the spec file and does not commit.
4. **Mark provenance.** Tag every feature and rule with exactly one of:
   - `[USER]`: the user decided it. Quote or cite the answer.
   - `[PROPOSED]`: an agent's idea. Give a one-line reason.
   - `[DEFAULT]`: the obvious answer from the source material.

   Done when no feature is untagged.
5. **Keep/cut pass.** Show the user every `[PROPOSED]` feature in plain player terms, using a multi-select "keep which?" question. Cut what they uncheck, and turn what they keep into `[USER]`. Ask for clarification when the user's answer is a sentence instead of a choice.
6. **Review once** for a broad spec: dispatch one `reviewer` to look for contradictions, scope holes, and inputs the spec ignores. Skip the review for a narrow one.
7. **Plain prose.** Delegate this step: tell the writer subagent, in its prompt, to pass its finished draft through the `unslop` skill if that skill is installed, loading it once and not again. The skill then loads only in the writer's context, and only for this one step. Skip the step when `unslop` is not installed.
8. **Commit.** The user approves the written spec, and then you commit it.

## Spec template

- Goals and non-goals.
- Players and flows.
- Rules, each tagged with its provenance.
- Data and contracts: the interfaces (contracts) each feature needs, named for the need. Tables and endpoints are implementation details, not rules. Follow the project's architecture guide in its AGENTS.md or CLAUDE.md; on the hexagonal layout, the `applying-hexagonal-architecture` skill.
- Failure modes.
- Open questions, each with a default.
- Deferrals.

Keep worked numbers in tables. Leave out code.

## Why the flow looks like this

- Provenance tags exist because an earlier spec mixed proposals in with decisions, and the user had to ask where features came from.
- Ask the questions before drafting. Answers that arrive after a draft forced two full rewrites once, at about 3M tokens.
