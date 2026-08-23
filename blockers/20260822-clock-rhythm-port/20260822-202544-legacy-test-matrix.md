---
id: legacy-test-matrix-count-mismatch
status: resolved
created_at: 2026-08-22T20:25:44+09:00
logical_agent_name: legacy-test-matrix
affected_task: P1 legacy behavior inventory
blocking_scope: full-required-path
user_action_required: false
---

# Blocker: legacy test inventory contract does not match the pinned source

## Status

- Blocked task: create `docs/verification/legacy-behavior-matrix.md` with exactly 49 source test files and 183 uniquely titled behavior rows.
- Impact: blocks the full P1 completion path because an exact, non-invented 183-row matrix cannot be produced from the pinned source.
- Source repository: `C:\Users\wndls\projects\clock-app`
- Source branch: `dev`
- Pinned commit: `f05a7a4b3349fec7c129d2a2a6a6cf4be1de8db9`

## Blocking condition

The pinned source contains exactly 49 `*.test.ts`/`*.test.tsx` files but only 182 executable Vitest `it(...)` or `test(...)` cases. The expected count of 183 is produced by a text-pattern count that also matches a JavaScript regular-expression method call in `src/shared/i18n/catalog.test.ts`:

```typescript
expect(englishTextValues.every((text: string): boolean => !/rhythm/i.test(text))).toBe(true);
```

The `.test(text)` expression is `RegExp.prototype.test`, not a Vitest case. It has no test title and therefore cannot supply the required exact nested title, stable behavior ID, or legitimate behavior row. Adding it would invent a test case; omitting it yields 182 rows and violates the fixed target count.

## Reconciliation evidence

1. Tracked inventory from the pinned commit:
   - Method: `git ls-tree -r --name-only HEAD` filtered by `\.test\.tsx?$`.
   - Result: 49 unique test files.
2. TypeScript compiler AST traversal:
   - Method: parse every tracked test file with TypeScript 6.0.3 and count only `CallExpression` nodes whose callee is the identifier `it` or `test`; literal titles and enclosing `describe` callbacks were also validated.
   - Result: 182 executable cases.
3. Independent text-pattern comparison:
   - Command: `rg -c --glob '*.test.ts' --glob '*.test.tsx' '\b(?:it|test)\s*\(' src`
   - Result: apparent total 183.
   - File-by-file comparison against the AST count found one and only one discrepancy: `src/shared/i18n/catalog.test.ts` reports 6 text matches but contains 5 AST-recognized Vitest cases.
   - Command: `rg -n --glob '*.test.ts' --glob '*.test.tsx' '\b(?:describe|it|test)\s*\(' src/shared/i18n/catalog.test.ts`
   - Result: five `it(...)` declarations plus the false-positive `/rhythm/i.test(text)` at line 35.
4. Alternate callable forms:
   - Search for `describe.*`, `it.*`, and `test.*` variants found no `it.each`, `it.skip`, `test.each`, `test.skip`, or other Vitest case form. The only property-form match relevant to the discrepancy is the regular-expression `.test(text)` call above.

## Repository state

The source repository was not modified. Before and after investigation, `git status --short --branch` returned:

```text
## dev...origin/dev
?? docs/superpowers/plans/2026-08-22-directory-architecture-refactor.md
```

`git rev-parse HEAD` remained `f05a7a4b3349fec7c129d2a2a6a6cf4be1de8db9`. The pre-existing untracked plan was not read, edited, staged, or removed.

## Artifacts and scope

- `docs/verification/legacy-behavior-matrix.md` was not created because no compliant 183rd behavior row exists.
- No source file, target plan, ledger, Git configuration/index, dependency, cache, build output, Dart/native code, or test was changed.
- This blocker report is the only file created.

## Required resolution

One authoritative input must change before the matrix can be completed:

- correct the expected inventory and P1/P22 contracts from 183 to 182 executable cases; or
- provide a source commit containing a real 183rd titled Vitest case.

After either resolution, the matrix can be generated without inventing a behavior or title.

## Resolution

The parent independently confirmed 49 tracked test files, 182 direct executable cases, and zero case variants. ADR 0016, the master plan, P1, P22, and the execution ledger were corrected to 182 executable cases. The resumed worker generated `docs/verification/legacy-behavior-matrix.md`, and the parent verified 182 sequential unique IDs, 49 unique files, 182 valid owners, 182 pending evidence states, and 0 invalid source declaration lines.
