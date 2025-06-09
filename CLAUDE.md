# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Build Commands
- Start server: `bundle exec rails s`
- Install dependencies: `bundle install`
- Database setup: `bundle exec rails db:prepare`
- Run all tests: `bundle exec rspec`
- Run single test: `bundle exec rspec spec/path/to_spec.rb:LINE_NUMBER`
- Deploy: `bundle exec cap production deploy`
- Run migrations: `bundle exec rails db:migrate`

## Project Overview
Greyhat.cl is a technology reflection blog focused on the balance between technology and life. Content themes include professional development for developers, conscious technology use, AI impact on work, and mental wellness in tech.

## Recent Major Updates (June 2025)

### Newsletter System Implementation
- **Newsletter Page**: `/newsletter` with dedicated navigation item
- **Substack Integration**: External subscription links with click tracking
- **Conversion Funnel**: Index → Articles → Newsletter → Subscriptions tracking
- **Newsletter Click Tracking**: Automatic tracking via Stimulus controller

### Dashboard Analytics Overhaul
- **Newsletter Conversion Metrics**: Complete funnel analysis with conversion rates
- **Site Health Monitoring**: Uptime, response time, error tracking via SiteHealth model
- **Content Performance Analytics**: Engagement scoring, trending posts, performance trends
- **Content Strategy Insights**: Automated insights on best publishing times, top topics
- **Tag Performance Analysis**: Topic-based content performance metrics

### Enhanced Content Features
- **Engagement Scoring**: Weighted algorithm (views 40% + comments 40% + recent activity 20%)
- **Performance Trending**: Week-over-week growth tracking
- **Newsletter Conversions**: Post-to-newsletter attribution tracking
- **Unique Visits Fix**: Proper unique visitor counting per post

### Technical Infrastructure
- **Visit Model Enhancement**: Action type enum for tracking different interaction types
- **SiteHealth Model**: Complete health monitoring system with anomaly detection
- **Database Migrations**: Added action_type to visits, site_healths table
- **Error Resilience**: Comprehensive nil-safe view implementations

## Code Style Guidelines
- Ruby: Use frozen_string_literal for all Ruby files
- Follow Rails naming conventions (snake_case for variables/methods, CamelCase for classes)
- Model validation and callbacks at the top of class definitions
- JS: Use Stimulus for JavaScript behavior
- CSS: Use existing classes when possible
- Use PostgreSQL for database features
- Error handling with Rails standard rescue_from in controllers
- Handle form validation with model validations and appropriate error rendering
- **View Safety**: Always protect against nil variables with `|| []`, `|| {}`, or `rescue` clauses

## Dependencies
- Devise for authentication
- Capistrano for deployment
- RSpec for testing
- Markdown with Redcarpet and CodeRay for syntax highlighting
- Stimulus for JavaScript components
- PostgreSQL with specific extensions (plpgsql, vector)

## Analytics & Tracking Architecture

### Visit Tracking System
- **Polymorphic visits**: Track both Post and Page visits
- **Action types**: page_view (0), newsletter_click (1), external_link (2)
- **Bot detection**: Comprehensive user agent filtering
- **Unique visitor logic**: 24-hour IP-based deduplication

### Newsletter Conversion Pipeline
1. **Index visits**: Homepage traffic measurement
2. **Article engagement**: Post view tracking
3. **Newsletter interest**: Newsletter page visits
4. **Conversion**: External Substack subscription clicks

### Content Performance Metrics
- **Engagement Score**: Multi-factor scoring algorithm
- **Performance Trends**: Comparative growth analysis
- **Tag Performance**: Topic-based content success metrics
- **Newsletter Attribution**: Post-to-subscription conversion tracking

## Future Enhancement Ideas

### Content Strategy Features
- **"Reflexión del día" Widget**: Daily tech/life balance insights
- **Herramientas Tech Recomendadas**: Community-driven tool recommendations
- **"¿Te Identificas?" Stories**: Relatable tech professional scenarios
- **Newsletter de "Equilibrio Tech"**: Enhanced newsletter branding
- **Artículos Relacionados por Tema**: Intelligent content recommendation
- **Comentarios Destacados**: Featured community discussions

### Advanced Analytics
- **Reading Time Estimation**: Average time spent on articles
- **Scroll Depth Tracking**: Content engagement measurement
- **Social Share Tracking**: Viral content identification
- **A/B Testing Framework**: Content optimization testing
- **Automated Reporting**: Weekly/monthly analytics emails

### User Experience Enhancements
- **Reading Progress Indicators**: Visual reading progress
- **Content Bookmarking Enhancement**: Improved save/organize functionality
- **Dark Mode Auto-detection**: System preference integration
- **Mobile Reading Optimization**: Enhanced mobile experience
- **Search Enhancement**: Full-text search with filters

### Health Monitoring Extensions
- **Performance Budget Alerts**: Automated performance degradation alerts
- **Database Query Monitoring**: Slow query identification
- **CDN Performance Tracking**: Asset delivery optimization
- **User Experience Monitoring**: Real user metrics
- **Automated Backup Verification**: Data integrity checks