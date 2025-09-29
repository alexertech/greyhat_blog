# Build stage
FROM ruby:3.3.4-slim AS builder

WORKDIR /app

# Install system dependencies for building
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    libvips \
    curl \
    git \
    nodejs \
    npm && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install gems (copy Gemfile first for better layer caching)
COPY Gemfile Gemfile.lock ./
RUN bundle config set --local deployment true && \
    bundle config set --local without development test && \
    bundle install --jobs 4 --retry 3

# Copy application code
COPY . .

# Precompile assets
RUN bundle exec rails assets:precompile

# Production stage
FROM ruby:3.3.4-slim AS production

WORKDIR /app

# Install only runtime dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    libpq-dev \
    libvips \
    curl && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Create app user for security
RUN groupadd -r app && useradd -r -g app app

# Copy gems from builder stage
COPY --from=builder /usr/local/bundle /usr/local/bundle

# Copy application and precompiled assets
COPY --from=builder --chown=app:app /app /app

# Create necessary directories and set permissions
RUN mkdir -p log tmp/pids tmp/cache tmp/sockets storage && \
    chown -R app:app log tmp storage && \
    chmod -R 755 log tmp storage

# Set environment
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true
ENV RAILS_LOG_TO_STDOUT=true

# Add healthcheck
HEALTHCHECK --interval=30s --timeout=5s --start-period=30s --retries=3 \
    CMD curl -f http://localhost:3000/health || exit 1

# Switch to non-root user
USER app

# Expose port
EXPOSE 3000

# Start server with proper signal handling
CMD ["bundle", "exec", "puma", "-C", "config/puma.rb"]
