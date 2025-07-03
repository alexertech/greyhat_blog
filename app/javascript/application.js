// application.js
import "@rails/activestorage";
import "@rails/actiontext";
import "./controllers"
import "bootstrap"
import "trix"
import "@rails/actiontext"
import "@rails/activestorage"
import "@hotwired/turbo-rails"

// Import charts functionality directly
import "./charts"

// Remove Rails UJS as it conflicts with Turbo
// Rails UJS is not needed when using Turbo Rails
