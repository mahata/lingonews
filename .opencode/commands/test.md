---
description: Run full CI checks (tests, lint, typecheck)
---

Run all CI checks for this project. Stop and report if any step fails.

1. Run RuboCop: `bin/rubocop`
2. Run bundle audit: `bin/bundler-audit`
3. Run Brakeman: `bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error`
4. Run TypeScript type check: `npx tsc --noEmit`
5. Build JS assets: `npm run build`
6. Set up the database: `bin/rails db:create db:schema:load`
7. Run the Rails test suite: `bin/rails test`
