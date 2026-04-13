# LingoNews

A bilingual news reader for language learning. Read news articles in English or Japanese, and hover over any sentence to reveal its translation — helping you learn a language through real content.

## Stack

- **Ruby 4.0.2** + **Rails 8.1.3**
- **PostgreSQL** database
- **React 19** + **TypeScript** frontend (bundled via esbuild / jsbundling-rails)

## Getting Started

### Prerequisites

- Ruby 4.0.2 (install via [mise](https://mise.jdx.dev/): `mise install`)
- PostgreSQL 17+
- Node.js 20+

### Setup

```bash
bin/setup          # installs gems, npm packages, creates DB, migrates, seeds
npm run build      # build the React/TypeScript frontend
bin/rails server   # http://localhost:3000
```

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

- **Article** — `title_en`, `title_ja`, `published_at`
- **Sentence** — belongs to Article, ordered by `position`, with `body_en` and `body_ja`
