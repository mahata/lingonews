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
