# Greyhat Blog

A Rails 8 blog engine with analytics dashboard, newsletter integration, and content management.

## Requirements

- Ruby 3.4.7
- Rails 8.1.1
- PostgreSQL 14+
- LibVips (image processing)

## Setup

### Native Development

```bash
# Install dependencies
bundle install

# Setup database
bundle exec rails db:prepare

# Start server
bundle exec rails s
```

### Docker Development

```bash
# Start environment
docker compose -f docker-compose.yml -f docker-compose.dev.yml up -d

# View logs
docker compose -f docker-compose.yml -f docker-compose.dev.yml logs -f web

# Run migrations
docker compose -f docker-compose.yml -f docker-compose.dev.yml exec web bundle exec rails db:migrate

# Stop
docker compose -f docker-compose.yml -f docker-compose.dev.yml down
```

## Configuration

Copy `.env.example` to `.env` and configure:

```bash
cp .env.example .env
```

Required environment variables:
- `POSTGRES_USER` - Database username
- `POSTGRES_PASSWORD` - Database password
- `POSTGRES_DB` - Database name
- `SECRET_KEY_BASE` - Rails secret (generate with `rails secret`)
- `RAILS_MASTER_KEY` - For credentials decryption

## Testing

```bash
# Run all tests
bundle exec rspec

# Run specific test
bundle exec rspec spec/path/to_spec.rb:LINE_NUMBER
```

## Deployment

### Docker Production

```bash
# Deploy
./bin/deploy-docker-compose

# Manual start
docker compose --env-file .env.production up -d

# View logs
docker compose --env-file .env.production logs -f web
```

### Capistrano (Legacy)

```bash
bundle exec cap production deploy
```

Database migrations run automatically during deployment.

## Project Structure

### Models

| Model | Purpose |
|-------|---------|
| `Post` | Blog articles with drafts, tags, images |
| `Page` | Static content pages |
| `Comment` | Post comments with moderation |
| `Tag` | Content categorization |
| `Visit` | Analytics tracking (page views, clicks) |
| `SiteHealth` | Uptime and performance monitoring |
| `Contact` | Contact form submissions |
| `User` | Authentication (Devise) |

### Key Features

- **Content**: Rich text editor (Trix/ActionText), draft system, tag management
- **Analytics**: Visit tracking, newsletter conversion funnel, device/browser stats
- **SEO**: Structured data, XML sitemaps, meta tags
- **Security**: Bot detection, spam filtering, CSRF protection

## Tech Stack

- Rails 8.1 with PostgreSQL
- Bootstrap 5.3 + Stimulus JS
- Propshaft + Dartsass
- ActionText + ActiveStorage
- Chartkick for analytics
- Devise authentication
- RSpec for testing

## Development Notes

- Follow Rails conventions (snake_case methods, CamelCase classes)
- Add `frozen_string_literal: true` to Ruby files
- Protect views against nil with `|| []` or `|| {}` patterns
- Use Stimulus for JavaScript behavior

## License

MIT License - see [LICENSE](LICENSE) for details.
