# RenderControl TODO

- Future tag idea: `{delay:lock:n}` or `{hold:n}`
- Purpose: keep an unskippable timing hold for scenes where `F` / `Space` should not shorten the wait.
- Current policy:
  - `{delay:n}` waits, but advance keys can shorten it.
  - `{pause}` always waits for user input.
