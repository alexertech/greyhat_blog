# Pin npm packages by running ./bin/importmap

pin "application"
pin "@hotwired/stimulus", to: "stimulus.min.js"
pin "@hotwired/stimulus-loading", to: "stimulus-loading.js"
pin_all_from "app/javascript/controllers", under: "controllers"
pin "trix"
pin "@rails/actiontext", to: "actiontext.esm.js"
pin "@rails/activestorage", to: "activestorage.esm.js"
pin "@hotwired/turbo-rails", to: "turbo.min.js"

# Bootstrap JS Components
pin "bootstrap", to: "https://ga.jspm.io/npm:bootstrap@5.3.3/dist/js/bootstrap.esm.js"
pin "@popperjs/core", to: "https://ga.jspm.io/npm:@popperjs/core@2.11.8/lib/index.js"

pin "highlight.js", to: "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/core.js"
pin "highlight.js/lib/languages/javascript", to: "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/javascript.js"
pin "highlight.js/lib/languages/ruby", to: "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/ruby.js"
pin "highlight.js/lib/languages/python", to: "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/python.js"
pin "highlight.js/lib/languages/css", to: "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/css.js"
pin "highlight.js/lib/languages/xml", to: "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/xml.js"
pin "highlight.js/lib/languages/bash", to: "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/bash.js"
pin "highlight.js/lib/languages/sql", to: "https://ga.jspm.io/npm:highlight.js@11.11.1/lib/languages/sql.js"
