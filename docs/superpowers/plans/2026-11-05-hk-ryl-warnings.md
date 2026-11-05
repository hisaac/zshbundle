# hk ryl Warnings: Upstream Handoff and Implementation Plan

> **For agentic workers:** Use the executing-plans skill if available. Recheck upstream before implementing; part of the requested fix already exists.

**Goal:** Resolve actionable ryl deprecations owned by hk without duplicating an existing fix or changing consumer configuration automatically.

**Architecture:** hk's Pkl builtins construct ryl commands and provide test fixtures. Fix only remaining deprecated configuration in hk-owned fixtures, with a regression check using ryl 0.28.0; preserve the already-correct command construction.

**Tech stack:** hk, Pkl, Rust build tooling, Bats, mise, ryl.

**Spec:** This handoff records the request and investigation from the zshbundle lint cleanup on November 5, 2026.

## Important discovery: the CLI fix already exists

Upstream repository: <https://github.com/jdx/hk>.

The bare-command warning was fixed on October 6, 2026:

- PR: <https://github.com/jdx/hk/pull/1655>
- Commit: `bebcd6eae9b5864f5514423cd598c42c140b6d14`
- Title: `fix(builtins): use ryl check to avoid the bare ryl deprecation warning`

The inspected upstream `main` HEAD was `e6f841a8ca08f33412d567c766dcf3162ee266eb`. Its `pkl/builtins/ryl.pkl` already uses:

| Operation | Command argv |
| --- | --- |
| check | `ryl check {{files}}` |
| check_diff | `ryl check --diff {{files}}` |
| check_list_files | `ryl check --list-files {{files}}` |
| fix | `ryl check --fix {{files}}` |

**Do not submit another PR for this command change.** Recheck current upstream and existing PRs before choosing remaining work.

## Original reproduction and warning ownership

Consumer repository: `hisaac/zshbundle`. Run `mise run chk`.

Observed installed tools: hk **2.11.1**, ryl **0.28.0**. However, the consumer's `hk.pkl` explicitly imports **hk@2.4.0** for both `Config.pkl` and `Builtins.pkl`. Upgrading the hk executable alone did not update those imports.

The v2.4.0 builtin invokes bare `ryl`, producing:

```text
warning: bare `ryl <paths>` is deprecated; use `ryl check <paths>` instead
```

That warning belongs to the old imported builtin. Adopting a newer compatible Pkl package is a separate consumer change, not a new upstream CLI fix. Review package migration requirements before upgrading imports.

The consumer's own `.config/ryl.toml` produces two additional warnings:

```text
`rules` is deprecated; use `lint.rules` instead
`per-file-ignores` is deprecated; use `lint.per-file-ignores` instead
```

Those belong to consumer configuration. Its relevant tables are `[rules]`, `[rules.comments]`, and `[per-file-ignores]`; migration moves them beneath `lint` while preserving values. Tombi also reports these deprecated config keys. **An hk upstream PR cannot eliminate warnings from this unmigrated consumer file.**

## Remaining upstream candidate

At the inspected HEAD, `pkl/builtins/ryl.pkl` still embeds an old `.ryl.toml` fixture using `[rules]` and nested `[rules.*]` tables. Meanwhile, `test/builtin_tool_stubs/ryl` pins **0.26.0**, older than the installed version that reports config deprecations.

Likely focused follow-up: migrate that hk-owned fixture to `[lint.rules]` and `[lint.rules.*]`, and exercise it with ryl 0.28.0. Confirm the warning is reproducible in hk's test environment before claiming a fix. Do not assume upgrading the tool stub is sufficient to detect stderr warnings: successful tests may tolerate them.

## Global constraints

- Work in a separate hk checkout; do not change zshbundle while implementing upstream work.
- Read hk's current `AGENTS.md`, `CONTRIBUTING.md`, and `docs/contributing.md` first.
- Preserve rule settings, check/fix outcomes, diff applicability, and file-argument boundaries.
- Do not suppress stderr or disable deprecation reporting.
- Avoid unrelated dependency updates, generated-file edits, and formatter/Markdown builtin changes.
- Determine compatibility with the current tool pin before changing configuration syntax. Test both 0.26.0 and 0.28.0 if retaining support for both; otherwise state the changed test-tool requirement.

## Files and review focus

| Upstream path | Responsibility |
| --- | --- |
| `pkl/builtins/ryl.pkl` | Existing commands, embedded config fixture, check/fix/diff tests |
| `test/builtin_tool_stubs/ryl` | Version used by builtin integration tests |
| `test/builtins_tests.bats` | Existing builtin test harness and patterns for focused tests |
| `pkl/builtins/test/helpers.pkl` | TestMaker helpers; inspect before adding assertions |

Check that clean YAML still passes, invalid YAML still fails, fixes produce the same content, diffs still apply, and captured output contains no deprecated-config warning. Preserve any intentional warning-level lint diagnostics: this is not a request to reject every warning.

## Execution checklist

- [ ] Recheck upstream HEAD, PR #1655, and open PRs for a fixture migration; stop if nothing remains to fix.
- [ ] Reproduce the deprecated fixture warning with ryl 0.28.0 and retain the output as before-evidence.
- [ ] Add a focused regression assertion in the existing test framework that fails on the deprecated-config warning. Use the actual embedded fixture, not an unrelated clean config. Ensure stderr is captured even when the lint command exits successfully.
- [ ] Run the regression before editing the fixture and confirm that it fails for the expected warning.
- [ ] Migrate only the embedded rule-table paths; update the ryl test pin if needed. Leave existing `ryl check` argv unchanged.
- [ ] Run the regression again and confirm that it passes while the existing check/fix/diff expectations remain intact.
- [ ] Run `mise run build`, then `mise run test:bats test/builtins_tests.bats` in hk. The harness arranges its tool-stub PATH; ensure the ryl tests actually run with the intended version. Use `hk test --step ryl` only with a config importing this checkout's builtins and the appropriate tool PATH.
- [ ] Run hk's required lint checks from its current contributor instructions. Record exact commands, versions, outcomes, and any tests not run.
- [ ] Prepare a focused PR if a change remains warranted. Suggested title: `fix(builtins): migrate ryl test configuration to lint tables`. Explain that bare invocation was already fixed in #1655 and that consumer configs still require their own migration.

## Acceptance and stop condition

The hk-owned fixture runs under ryl 0.28.0 without deprecated configuration warnings; existing ryl check/fix/diff tests pass; the PR introduces no duplicate CLI change or automatic migration of consumer files. Stop after the focused upstream change and validation, or report that upstream has already resolved it.

hk currently requires AI-authored GitHub content to include a disclosure. Follow the current `AGENTS.md`; use actual runtime identifiers, not guessed ones.

## Local state and scope exclusions

The last zshbundle `mise run chk` passed with these deprecation warnings. Separate fixes already exclude `scripts/update-hk-import.zsh` from shfmt in `hk.pkl` and `.ryl_cache` from `.config/ls-lint.yml`. Do not include those in an hk PR.

This handoff only inspected upstream source and history remotely; no hk checkout was built or tested. No upstream PR was opened, and no consumer ryl config or Pkl package import was migrated.
