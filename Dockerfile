# syntax=docker/dockerfile:1

# Stage 1: Build JavaScript assets
FROM node:22-slim AS node-build

WORKDIR /app

COPY package.json package-lock.json ./
RUN npm ci

COPY app/javascript app/javascript
COPY tsconfig.json ./

ENV NODE_ENV=production
RUN npm run build:production

# Stage 2: Build gems with native extensions
FROM ruby:4.0.2-slim AS gem-build

RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      build-essential \
      libpq-dev \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

WORKDIR /rails

COPY Gemfile Gemfile.lock ./
RUN bundle install && \
    rm -rf ~/.bundle/ "${BUNDLE_PATH}"/ruby/*/cache "${BUNDLE_PATH}"/ruby/*/bundler/gems/*/.git

# Stage 3: Runtime image
FROM ruby:4.0.2-slim AS base

WORKDIR /rails

# Install only runtime packages
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
      curl \
      libjemalloc2 \
      libpq-dev \
      libvips \
    && rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*

# Enable jemalloc for reduced memory usage and fragmentation
ENV LD_PRELOAD="libjemalloc.so.2"

# Set production environment
ENV RAILS_ENV="production" \
    BUNDLE_DEPLOYMENT="1" \
    BUNDLE_PATH="/usr/local/bundle" \
    BUNDLE_WITHOUT="development:test"

# Copy compiled gems from build stage
COPY --from=gem-build /usr/local/bundle /usr/local/bundle

# Copy application code
COPY . .

# Copy JS build artifacts from node stage
COPY --from=node-build /app/app/assets/builds app/assets/builds

# Precompile assets (bootsnap + propshaft)
RUN SECRET_KEY_BASE_DUMMY=1 ./bin/rails assets:precompile

# Entrypoint sets up the container
ENTRYPOINT ["/rails/bin/docker-entrypoint"]

EXPOSE 3000
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
