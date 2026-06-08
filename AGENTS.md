# AstralDivide Agent Rules

These rules apply to all automated edits in this repository.

## Owner

- The project owner is Shoya Aizawa.
- Preferred nickname: Harinezumi / はりねずみ.
- When the user writes in Japanese, respond in Japanese.

## File Encoding And Line Endings

- All source files must use UTF-8 encoding.
- All text source files must use CRLF line endings.
- Do not rewrite an existing file until its current encoding has been verified.
- If encoding is uncertain, avoid broad rewrites and use the smallest safe patch possible.
- After editing `.bat` files, run `RefreshLineEndingToCRLF.ps1` to normalize line endings.

## Comments

- All newly added code comments must be written in English.
- If an existing corrupted or mojibake comment must be touched, replace it with an English comment or remove it.
- Do not introduce new non-English code comments.

## Batch File Safety

- Treat mojibake or corrupted comment lines as unsafe, because they can hide or swallow executable code.
- If a comment line contains executable code accidentally merged into it, restore the executable code explicitly.
- Prefer minimal edits for legacy batch files.

## Workflow Expectations

- Verify UTF-8 and CRLF after editing critical batch files.
- When cleaning legacy or debug code, prefer removing dead paths first, then remove remaining stubs and labels.
- Avoid changing runtime behavior unless the task explicitly requires it.
