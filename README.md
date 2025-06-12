# Greyhat Blog Engine

A modern, feature-rich blog engine built with Ruby on Rails 7.2 and PostgreSQL. Designed for tech blogs, personal websites, and professional content creators who need a robust, scalable, and beautiful blogging platform.

🌐 **Live Demo**: [greyhat.cl](https://www.greyhat.cl)

![Greyhat Demo](greyhat.gif)

## ✨ Key Features

### 🎨 **Modern Design & UX**
- **Responsive Design**: Mobile-first approach with Bootstrap 5.3
- **Dark Mode Support**: Full dark/light theme toggle with system preference detection
- **Professional UI**: Clean, modern interface with Font Awesome icons
- **Touch-Friendly**: Optimized for mobile devices with proper touch targets
- **Accessibility**: WCAG AA compliant color contrast ratios

### ✍️ **Content Management**
- **Rich Text Editor**: Advanced Trix editor with image paste functionality
- **Draft System**: Save posts as drafts before publishing
- **Intelligent Tag System**: AI-powered tag suggestions with content analysis
- **Tag Auto-Complete**: Interactive tag management with smart suggestions
- **Image Handling**: ActiveStorage with optimized WebP variants (1536x474 banner, 768x237 medium, 480x148 thumb)
- **Advanced SEO**: Complete SEO suite with structured data, sitemaps, and social media optimization
- **Reading Time**: Automatic reading time calculation

### 📊 **Analytics & Insights**
- **Modern Dashboard**: Beautiful, responsive admin interface with comprehensive analytics
- **Real-time Charts**: Interactive charts powered by Chart.js and Chartkick
- **Advanced Visitor Tracking**: IP-based unique visit counting with 24-hour deduplication
- **Search Analytics**: Popular search terms extraction and analysis
- **Traffic Sources**: Social media, search engines, and referrer categorization
- **Device Analytics**: Browser, OS, and device type breakdown with visual charts
- **Bot Detection**: Sophisticated bot filtering with human vs. automated traffic separation
- **Performance Metrics**: Visit statistics by page, time period, and content type
- **Newsletter Analytics**: Complete conversion funnel tracking (Index → Articles → Newsletter → Subscriptions)
- **Content Performance**: Engagement scoring with weighted algorithms and trending analysis
- **Site Health Monitoring**: Uptime, response time, and error tracking with anomaly detection

### 💬 **Engagement Features**
- **Comment System**: Secure commenting with moderation queue
- **Anti-Spam Protection**: Honeypot fields and content validation
- **Bookmark System**: Client-side bookmarks for anonymous users
- **Social Sharing**: Built-in sharing for Twitter, LinkedIn, Facebook, WhatsApp
- **Related Posts**: Tag-based content recommendations

### 🔧 **Developer Experience**
- **Performance Optimized**: N+1 query prevention with proper eager loading
- **Modern JavaScript**: Stimulus controllers for interactive features
- **Responsive Search**: Header-integrated search with mobile optimization
- **Tag Autocomplete**: Dynamic tag suggestions with click-to-add functionality
- **Clean Codebase**: Well-organized, documented, and maintainable code
- **Database Optimization**: Advanced indexing with PostgreSQL GIN indexes for text search
- **Counter Caches**: Optimized visit counting for high-performance analytics
- **Query Optimization**: Complex analytics queries optimized for millisecond response times

## 🛠 Tech Stack

| Component | Technology |
|-----------|------------|
| **Backend** | Ruby on Rails 7.2.2 |
| **Database** | PostgreSQL 14+ |
| **Frontend** | Bootstrap 5.3, Stimulus JS |
| **Rich Text** | Trix + ActionText |
| **Images** | ActiveStorage with WebP variants |
| **Charts** | Chart.js + Chartkick |
| **Analytics** | Groupdate gem for time-based data |
| **Icons** | Font Awesome 6.7 |
| **Pagination** | will_paginate |
| **Authentication** | Devise |

## 🚀 Quick Start

### Prerequisites
- Ruby 3.3+ 
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)
- ImageMagick (for image processing)
- LibVips (for image processing)

### Installation

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/greyhat-blog.git
   cd greyhat-blog
   ```

2. **Install dependencies**
   ```bash
   bundle install
   ```

3. **Setup database**
   ```bash
   rails db:create
   rails db:migrate
   rails db:seed
   ```

4. **Start the server**
   ```bash
   rails server
   ```

5. **Access the application**
   - **Public site**: http://localhost:3000
   - **Admin login**: http://localhost:3000/users/sign_in
     - Email: `admin@example.com`
     - Password: `password12356`

## ⚙️ Configuration

### Environment Variables

Create a `.env` file in the root directory:

```env
# Database
DATABASE_URL=postgresql://username:password@localhost/greyhat_blog_development

# Rails
RAILS_ENV=development
SECRET_KEY_BASE=your_secret_key_here

# Email (optional)
SMTP_SERVER=smtp.gmail.com
SMTP_PORT=587
SMTP_USERNAME=your_email@gmail.com
SMTP_PASSWORD=your_app_password

# Storage (production)
AWS_ACCESS_KEY_ID=your_aws_key
AWS_SECRET_ACCESS_KEY=your_aws_secret
AWS_REGION=us-east-1
AWS_BUCKET=your-bucket-name
```

### Key Configuration Files

- **Database**: `config/database.yml`
- **Routes**: `config/routes.rb`
- **Assets**: `config/importmap.rb`
- **Storage**: `config/storage.yml`
- **Mailer**: `config/environments/production.rb`

### Customization Options

#### 1. **Branding**
Update your site branding in:
- Logo: `app/assets/images/logo.png`
- Favicon: `public/favicon.ico`
- Site name: Update in layouts and meta tags

#### 2. **Styling**
Main stylesheet: `app/assets/stylesheets/application.scss`
- Customize CSS variables for colors
- Modify Bootstrap theme variables
- Add custom component styles

#### 3. **Content**
- **Pages**: Edit `app/views/pages/` for static content
- **Email templates**: Modify `app/views/devise/mailer/`
- **Navigation**: Update `app/views/partials/_navigation.html.erb`

## 📋 Usage Guide

### Content Management

#### Creating Posts
1. Navigate to `/dashboard`
2. Click "Administrar artículos"
3. Click "New Post"
4. Add title, content, tags, and featured image
5. Toggle draft status as needed

#### Intelligent Tag Management
- **AI-Powered Suggestions**: Content analysis generates relevant tag suggestions
- **Technology Detection**: Automatically suggests tech-related tags (frameworks, languages, tools)
- **Psychology & Wellness**: Smart suggestions for mental health and digital wellness content
- **Auto-suggestions**: Popular existing tags appear as clickable suggestions
- **Manual entry**: Type comma-separated tags or use the suggestion system
- **Interactive UI**: Click to add, X to remove tags with smooth animations
- **Smart creation**: New tags created automatically when you type custom ones

#### Comment Moderation
1. Go to Dashboard → "Moderar comentarios"
2. Review pending comments
3. Approve or delete as needed
4. Monitor spam patterns

### Analytics & Insights

#### Modern Dashboard (`/dashboard`)
- **Key Metrics Cards**: Total visits, published posts, approved comments, daily traffic
- **Interactive Charts**: 30-day visit trends with Chart.js visualization
- **Traffic Sources**: Pie chart breakdown of social media, search engines, direct, and referral traffic
- **Popular Search Terms**: Real-time analysis of search queries that brought visitors
- **Referrer Analysis**: Categorized traffic sources including LinkedIn, Substack, and other platforms
- **Device Analytics**: Browser, operating system, and device type breakdowns with donut charts
- **Top Content**: Most visited posts with engagement metrics and quick action buttons

#### Advanced Analytics (`/dashboards/stats`)
- **Flexible Time Periods**: 7, 30, 90 day analysis views
- **Hourly Traffic Patterns**: Understand peak usage times
- **Content Performance**: Detailed post and page analytics
- **Traffic Source Deep Dive**: Comprehensive referrer analysis with categorization
- **Visitor Behavior**: Advanced metrics for content optimization

## ⚡ Performance Features

### Database Optimization
- **Advanced Indexing**: PostgreSQL GIN indexes for blazing-fast text search
- **Composite Indexes**: Optimized for complex analytics queries (newsletter conversions, user agent analysis)
- **Counter Caches**: Real-time visit counting without expensive COUNT queries
- **Partial Indexes**: Targeted indexing for specific query patterns

### Query Performance
- **Newsletter Conversion Tracking**: Complex self-join queries optimized from ~2s to ~200ms
- **Most Visited Posts**: Subquery elimination using counter caches (~80% performance improvement)
- **User Agent Analytics**: Single optimized query vs multiple separate queries (~70% faster)
- **Tag-Based Searches**: Composite indexing for related posts queries (~60% improvement)

### SEO & Core Web Vitals
- **Structured Data**: Rich JSON-LD markup for enhanced search engine understanding
- **XML Sitemap**: Dynamic sitemap generation with image and news sections
- **Resource Optimization**: DNS prefetching, preloading, and efficient font loading
- **Canonical URLs**: Proper duplicate content handling

## 🔒 Security Features

### Built-in Protection
- **CSRF Protection**: Rails built-in CSRF tokens
- **SQL Injection**: ActiveRecord ORM protection
- **XSS Prevention**: Content sanitization and escaping
- **Spam Filtering**: Honeypot fields and content validation
- **Bot Detection**: User-agent analysis and filtering

### Recommended Security Measures
```ruby
# Add to config/environments/production.rb
config.force_ssl = true
config.ssl_options = { hsts: { subdomains: true } }
```

## 🚀 Deployment

### Recommended Stack
- **Platform**: Heroku, DigitalOcean, AWS
- **Database**: PostgreSQL (managed service recommended)
- **Storage**: AWS S3 for images and assets
- **CDN**: CloudFlare for performance and security

### Deployment Checklist
- [ ] Set environment variables
- [ ] Configure SSL certificates
- [ ] Set up database backups
- [ ] Configure email service
- [ ] Set up monitoring and logging
- [ ] Configure CDN and asset delivery

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch (`git checkout -b feature/amazing-feature`)
3. Commit your changes (`git commit -m 'Add amazing feature'`)
4. Push to the branch (`git push origin feature/amazing-feature`)
5. Open a Pull Request

### Development Guidelines
- Follow Ruby Style Guide
- Write tests for new features
- Update documentation
- Ensure mobile responsiveness
- Test dark mode compatibility

## 📝 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

### What this means:
- ✅ **Commercial use allowed** - Use in commercial projects
- ✅ **Modification allowed** - Customize and extend the code
- ✅ **Distribution allowed** - Share and redistribute freely
- ✅ **Private use allowed** - Use for personal/internal projects
- ⚠️ **Attribution required** - Include copyright notice in copies
- ⚠️ **No warranty** - Software provided "as is"

### Quick Attribution Example:
```
Built with Greyhat Blog Engine by Alex Barrios
https://github.com/yourusername/greyhat-blog
```

## 🎯 Roadmap

### Recently Completed ✅
- [x] **Advanced SEO**: Complete SEO suite with structured data, XML sitemaps, and robots.txt
- [x] **Performance Optimization**: Database indexing, counter caches, and query optimization
- [x] **Newsletter Analytics**: Complete conversion funnel tracking and analytics
- [x] **Site Health Monitoring**: Comprehensive uptime and performance monitoring

### Upcoming Features
- [ ] **Multi-language Support**: i18n for Spanish/English
- [ ] **Newsletter Integration**: Advanced email subscription management
- [ ] **Redis Caching**: Fragment and query caching for enhanced performance
- [ ] **Social Features**: User profiles and social login
- [ ] **API**: RESTful API for mobile apps
- [ ] **Webhooks**: Integration with external services

### Performance Improvements
- [x] **Database Optimization**: Advanced PostgreSQL indexing with GIN indexes
- [x] **Query Optimization**: Complex analytics queries optimized for sub-second response
- [x] **Counter Caches**: Automated visit counting for high-performance analytics
- [ ] **CDN Integration**: Asset optimization and delivery
- [ ] **Application Monitoring**: Enhanced performance monitoring and alerting

## 📞 Support & Contact

- **Author**: Alex Barrios
- **Website**: [alexertech.com](https://www.alexertech.com)
- **LinkedIn**: [linkedin.com/in/alexertech](https://linkedin.com/in/alexertech)

## 🏆 Credits

Built with ❤️ by [Alex Barrios](https://www.alexertech.com) using modern web technologies and best practices.

Special thanks to the Ruby on Rails community and all the open-source contributors who made this project possible.

---

⭐ **Star this repo** if you find it useful! Pull requests and feedback are always welcome.