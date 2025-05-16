# Greyhat Blog Engine

A modern blog engine built with Ruby on Rails 7 and PostgreSQL, featuring a responsive Bootstrap 5 UI. Visit the live version at: [greyhat.cl](http://www.greyhat.cl)

## Features

- **Responsive Design**: Mobile-friendly interface with Bootstrap 5
- **Rich Content Editor**: Trix editor with image paste functionality
- **Markdown Support**: Write blog posts with rich formatting
- **Image Management**: ActiveStorage for image uploads and variants
- **Analytics**: Visitor tracking for blog posts and pages
- **Admin Dashboard**: Statistics and content management
- **SEO-Friendly**: Meta descriptions and optimized content structure
- **Comment System**: Secure comment system with moderation queue

## Tech Stack

- Ruby on Rails 7.2
- PostgreSQL database
- Bootstrap 5.3 for UI
- Trix + ActionText for rich content
- Stimulus for JavaScript functionality
- Font Awesome for icons
- Turbolinks for faster page loads

## Demo

![Greyhat Demo](greyhat.gif)

## Recent Improvements

- ✅ Migrated UI from Primitive CSS to Bootstrap 5
- ✅ Added rich text editing with Trix editor
- ✅ Implemented image paste functionality
- ✅ Optimized performance with proper image handling
- ✅ Improved responsive layout for all screen sizes
- ✅ Enhanced service cards with icons and descriptions
- ✅ Created consistent card-based design across the site
- ✅ Added secure comment system with moderation capabilities
- ✅ Implemented anti-spam measures with honeypot field
- ✅ Added real-time character counter for comments
- ✅ Built comment moderation dashboard for administrators

## Comments System

The blog features a secure commenting system with the following features:

- 140-character limit for concise comments
- Required username and email fields
- Anti-spam measures with honeypot field
- No links allowed in comments
- Automatic moderation queue for review
- Admin dashboard for approving/rejecting comments
- Beautiful avatar placeholders with username initials
- Responsive design that works on all devices

## To-Do:

- General
  - Cleanup of older non used ruby folders and files
  - Cleanup of scaffolding code
  - Add historic visit tracking counter: Current solution only gives unique visitors

- Dashboard
  - Change dashboard interface metrics with graphics

- Posts
  - Blob rendering time is slower, need to create variant versions using Active Storage
  - Add checkbox to enable / disable if a post should be public

- Comments
  - ✅ Allow comments in posts
  - Add email notifications for new comments
  - Add CAPTCHA as an additional spam protection measure