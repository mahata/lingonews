---
description: Run full CI checks (tests, lint, typecheck)
---

Run all CI checks for this project. Stop and report if any step fails.

1. Run RuboCop: `bin/rubocop`
2. Run TypeScript type check: `npx tsc --noEmit`
3. Build JS assets: `npm run build`
4. Run the Rails test suite: `bin/rails test`
