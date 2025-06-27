import { Controller } from "@hotwired/stimulus"
import hljs from "highlight.js"
import "highlight.js/lib/languages/javascript"
import "highlight.js/lib/languages/ruby"
import "highlight.js/lib/languages/python"
import "highlight.js/lib/languages/css"
import "highlight.js/lib/languages/xml"
import "highlight.js/lib/languages/bash"
import "highlight.js/lib/languages/sql"

export default class extends Controller {
  connect() {
    this.highlightCodeBlocks()
  }

  highlightCodeBlocks() {
    // Find all code blocks in the content
    const codeBlocks = this.element.querySelectorAll('pre code, code')
    
    codeBlocks.forEach((block) => {
      // Skip if already highlighted
      if (block.classList.contains('hljs')) {
        return
      }
      
      // Apply highlighting
      hljs.highlightElement(block)
    })
  }
}