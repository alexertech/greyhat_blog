# Greyhat Blog Engine

A blog engine written entirely in Ruby on Rails + PostgreSQL with [Primivite UI](https://taniarascia.github.io/primitive/) as CSS template. The live version is available at: [greyhat.cl](http://www.greyhat.cl)

## Demo

![Greyhat Demo](greyhat.gif)


## To-Do:

- General
  - Migrate UI from Primitive CSS to Bulma CSS
  - Cleanup of older non used ruby folders and files
  - Cleanup of scaffolding code
  - Add historic visit tracking counter: Current solution only gives unique visitors

- Dashboard
  - Change dashboard interface metrics with graphics

- Posts
  - Blob rendering time is slower, need to create variant versions using Active Storage
  - Add checkbox to enable / disable if a post should be public
  - ✅ Markdown support with Trix editor and image paste functionality

- Comments
  - Allow comments in posts