# Lingonews

A bilingual (Japanese/English) news reader built with Rails 8.1 and React 19. Fetches Japanese news articles via RSS, summarizes them into bilingual sentence pairs using the GitHub Copilot SDK, and presents them with hover-to-reveal translations.

## Tech Stack

- **Backend**: Ruby 4.0.2, Rails 8.1, PostgreSQL 17
- **Frontend**: React 19, TypeScript 6, esbuild
- **Deployment**: Fly.io (region: nrt)
- **Runtime management**: mise (Ruby), .node-version (Node 22)

## Project Structure

- `app/controllers/` -- Rails controllers; API endpoints under `api/`
- `app/models/` -- ActiveRecord models (Article, Sentence)
- `app/services/news/` -- News pipeline: RSS fetching, article fetching, summarization, updater
- `app/javascript/` -- React/TypeScript SPA (entry: `application.tsx`)
- `app/javascript/components/` -- React components (App, ArticleList, ArticleShow)
- `config/news_sources.yml` -- RSS feed sources
- `script/summarize_article.ts` -- Copilot SDK summarizer script
- `test/` -- Minitest test files

## Commands

```sh
bin/dev                          # Start Rails + esbuild watcher
docker compose up -d             # Start PostgreSQL
bin/rails db:create db:migrate   # Set up database
bin/rails test                   # Run Minitest suite
bin/rubocop                      # RuboCop (rubocop-rails-omakase)
npx tsc --noEmit                 # TypeScript type checking
npm run build                    # Build JS assets with esbuild
bin/bundler-audit                # Gem vulnerability scan
bin/brakeman --quiet --no-pager --exit-on-warn --exit-on-error
```

## Conventions

- Follow the rules in `.github/copilot-instructions.md`
- Ruby code follows rubocop-rails-omakase style (no custom overrides)
- TypeScript strict mode is enabled
- The React SPA is served from a single Rails `pages#index` action; client-side routing via react-router-dom
- API endpoints are namespaced under `/api` (e.g., `/api/articles`)
- No JavaScript-side linting or formatting tools; rely on TypeScript compiler for type safety
