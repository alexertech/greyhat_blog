FROM ruby:3.3.4-slim

WORKDIR /app

# Install system dependencies
RUN apt-get update -qq && \
    apt-get install --no-install-recommends -y \
    build-essential \
    libpq-dev \
    libvips \
    curl \
    git && \
    rm -rf /var/lib/apt/lists /var/cache/apt/archives

# Install gems
COPY Gemfile Gemfile.lock ./
RUN bundle install

# Copy application code
COPY . .

# Create necessary directories and set permissions
RUN mkdir -p log tmp/pids tmp/cache tmp/sockets storage && \
    chmod -R 755 log tmp storage

# Set environment
ENV RAILS_ENV=production
ENV RAILS_SERVE_STATIC_FILES=true

CMD ["./bin/rails", "server"]
