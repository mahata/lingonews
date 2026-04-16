[![CI](https://github.com/mahata/lingonews/actions/workflows/ci.yml/badge.svg)](https://github.com/mahata/lingonews/actions/workflows/ci.yml) [![Fly Deploy](https://github.com/mahata/lingonews/actions/workflows/fly-deploy.yml/badge.svg)](https://github.com/mahata/lingonews/actions/workflows/fly-deploy.yml) [![News Update](https://github.com/mahata/lingonews/actions/workflows/news-update.yml/badge.svg)](https://github.com/mahata/lingonews/actions/workflows/news-update.yml)

# LingoNews

A bilingual news reader for language learning. Read news articles in English or Japanese, and hover over any sentence to reveal its translation — helping you learn a language through real content.

## Stack

- **Ruby 4.0.2** + **Rails 8.1.3**
- **PostgreSQL** database (via Docker)
- **React 19** + **TypeScript** frontend (bundled via esbuild / jsbundling-rails)

## Getting Started

### Prerequisites

- Ruby 4.0.2 (install via [mise](https://mise.jdx.dev/): `mise install`)
- Docker (for PostgreSQL)
- Node.js 20+

### Setup

```bash
docker compose up -d   # start PostgreSQL
bin/setup              # installs gems, npm packages, creates DB, migrates, seeds
npm run build          # build the React/TypeScript frontend
bin/rails server       # http://localhost:3000
```

To stop the database: `docker compose down` (add `-v` to also remove data).

Or use `bin/dev` to run Rails + esbuild watcher together via Foreman.

### Git Hooks (Lefthook)

This project uses [Lefthook](https://github.com/evilmartians/lefthook) to run lint checks automatically before commits and pushes. Hooks are installed automatically when you run `npm install`.

- **Pre-commit** — runs RuboCop and TypeScript type checking in parallel, only on staged files. This catches style violations and type errors before they reach CI.
- **Pre-push** — runs Brakeman (security analysis) and bundler-audit (gem vulnerability scan) in parallel. These slower, full-project checks run once before code leaves your machine.

To skip hooks temporarily, pass `--no-verify` (e.g., `git commit --no-verify`).

### Running Tests

```bash
bin/rails test
```

## Features

- 📰 **Bilingual articles** with sentence-level EN↔JA alignment
- 🔄 **Language toggle** in the navbar (cookie-based, no login required)
- 🔍 **Hover-to-reveal** translations on each sentence
- 📡 **JSON API** — `GET /api/articles` and `GET /api/articles/:id`

## Data Model

- **Article** — `title_en`, `title_ja`, `published_at`, `source_url`
- **Sentence** — belongs to Article, ordered by `position`, with `body_en` and `body_ja`

## Updating News

LingoNews can automatically fetch real articles from NHK News Web, summarize them into bilingual sentence pairs using the [GitHub Copilot SDK](https://github.com/github/copilot-sdk), and store them in the database.

### Prerequisites

- A **GitHub Personal Access Token** with a Copilot subscription (set as `GITHUB_TOKEN`)
- The Copilot CLI is bundled automatically by the SDK — no separate install needed

### How it works

```
NHK RSS Feed → Fetch full article HTML → Copilot SDK (bilingual summarize) → Database
```

1. **`News::RssFetcher`** parses the NHK RSS feed and skips articles already in the database (via `source_url`)
2. **`News::ArticleFetcher`** downloads each article's HTML and extracts the text using Nokogiri
3. **`News::ArticleSummarizer`** calls `script/summarize_article.ts` — a Node.js script that uses `@github/copilot-sdk` to produce bilingual sentence pairs (the number of sentences is determined by the article's length)
4. **`News::Updater`** orchestrates the pipeline and saves `Article` + `Sentence` records

### Usage

```bash
GITHUB_TOKEN=ghp_your_token bin/rails news:update
```

The task is idempotent — re-running it only fetches new articles not yet in the database.

## Deploying to Fly.io

### Prerequisites

- [flyctl CLI](https://fly.io/docs/flyctl/install/) installed and authenticated (`fly auth login`)

### Initial Setup

```bash
# Create the Fly app (does not deploy yet)
fly launch --no-deploy

# Create a single-node Postgres cluster (cheapest option)
fly postgres create --name lingonews-db --region nrt --vm-size shared-cpu-1x --volume-size 1

# Attach the database (sets DATABASE_URL automatically)
fly postgres attach lingonews-db

# Set the Rails master key
fly secrets set RAILS_MASTER_KEY=$(cat config/master.key)
```

### Deploy

```bash
fly deploy
```

### Useful Commands

```bash
fly status              # check app status
fly logs                # stream logs
fly ssh console         # SSH into the running machine
fly ssh console -C "/rails/bin/rails console"  # Rails console
fly postgres connect -a lingonews-db            # psql into the database
```

### Cost Notes

The app is configured for minimal cost (~$3–4/month):

- **Machine**: `shared-cpu-1x` with 256MB RAM
- **Postgres**: single-node, 1GB volume
- **Auto-stop**: machines stop when idle and restart on incoming requests (adds ~2–5s cold start)
