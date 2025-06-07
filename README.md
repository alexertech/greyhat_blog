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
- **Tag Management**: Interactive tag system with auto-suggestions
- **Image Handling**: ActiveStorage with automatic WebP variants (thumb, medium, banner)
- **SEO Optimization**: Meta descriptions, Open Graph, and Twitter Card support
- **Reading Time**: Automatic reading time calculation

### 📊 **Analytics & Insights**
- **Advanced Visitor Tracking**: IP-based unique visit counting with 24-hour deduplication
- **Bot Detection**: Sophisticated bot filtering with human vs. automated traffic separation
- **Performance Analytics**: Visit statistics by page, time period, and content type
- **Dashboard**: Beautiful admin interface with comprehensive statistics
- **Referrer Tracking**: Source analysis and traffic pattern insights

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

## 🛠 Tech Stack

| Component | Technology |
|-----------|------------|
| **Backend** | Ruby on Rails 7.2.2 |
| **Database** | PostgreSQL 14+ |
| **Frontend** | Bootstrap 5.3, Stimulus JS |
| **Rich Text** | Trix + ActionText |
| **Images** | ActiveStorage with WebP variants |
| **Icons** | Font Awesome 6.7 |
| **Pagination** | will_paginate |
| **Authentication** | Devise |

## 🚀 Quick Start

### Prerequisites
- Ruby 3.3+ 
- PostgreSQL 14+
- Node.js 18+ (for asset compilation)
- ImageMagick (for image processing)

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
     - Password: `password123`

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

#### Tag Management
- **Auto-suggestions**: Popular tags appear as clickable suggestions
- **Manual entry**: Type comma-separated tags
- **Interactive UI**: Click to add, X to remove tags
- **Smart creation**: New tags created automatically

#### Comment Moderation
1. Go to Dashboard → "Moderar comentarios"
2. Review pending comments
3. Approve or delete as needed
4. Monitor spam patterns

### Analytics & Insights

#### Dashboard Metrics
- **Visit Statistics**: Total, daily, weekly breakdowns
- **Content Performance**: Most visited posts and pages
- **Traffic Analysis**: Human vs. bot traffic percentages
- **Referrer Data**: Traffic source analysis

#### Advanced Analytics
Access detailed stats at `/dashboards/stats`:
- Daily visit trends (7, 30, 90 day views)
- Hourly traffic patterns
- Content type performance
- Visitor behavior analysis

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

### Upcoming Features
- [ ] **Multi-language Support**: i18n for Spanish/English
- [ ] **Newsletter Integration**: Email subscription management
- [ ] **Advanced SEO**: Sitemap generation and schema markup
- [ ] **Performance**: Redis caching and optimization
- [ ] **Social Features**: User profiles and social login
- [ ] **API**: RESTful API for mobile apps
- [ ] **Webhooks**: Integration with external services

### Performance Improvements
- [ ] **Caching**: Fragment and query caching
- [ ] **CDN Integration**: Asset optimization
- [ ] **Database**: Query optimization and indexing
- [ ] **Monitoring**: Application performance monitoring

## 📞 Support & Contact

- **Author**: Alex Barrios
- **Website**: [alexertech.com](https://www.alexertech.com)
- **LinkedIn**: [linkedin.com/in/alexertech](https://linkedin.com/in/alexertech)
- **Issues**: [GitHub Issues](https://github.com/yourusername/greyhat-blog/issues)

## 🏆 Credits

Built with ❤️ by [Alex Barrios](https://www.alexertech.com) using modern web technologies and best practices.

Special thanks to the Ruby on Rails community and all the open-source contributors who made this project possible.

---

⭐ **Star this repo** if you find it useful! Pull requests and feedback are always welcome.