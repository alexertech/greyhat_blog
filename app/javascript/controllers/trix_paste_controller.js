import { Controller } from "@hotwired/stimulus"
import { DirectUpload } from "@rails/activestorage"
import * as Trix from "trix"

// This controller handles pasting images into Trix editor
export default class extends Controller {
  static targets = ["editor"]

  connect() {
    // Get the Trix editor element from the controller target
    this.trixElement = this.hasEditorTarget ? this.editorTarget : this.element.querySelector("trix-editor")
    
    if (this.trixElement) {
      // Add paste event listener directly to the Trix editor element
      this.trixElement.addEventListener("paste", this.handlePaste.bind(this))
    }
  }

  disconnect() {
    // Clean up event listener when controller disconnects
    if (this.trixElement) {
      this.trixElement.removeEventListener("paste", this.handlePaste.bind(this))
    }
  }

  handlePaste(event) {
    // Check if the paste event contains clipboard items (for images)
    if (!event.clipboardData || !event.clipboardData.items) return

    const items = event.clipboardData.items
    const imageItems = Array.from(items).filter(item => item.type.includes("image"))
    
    // If there are no image items, return and let the default paste behavior continue
    if (imageItems.length === 0) return

    // Prevent the default paste behavior if we have images
    event.preventDefault()
    
    // Process each image item
    imageItems.forEach(item => {
      const file = item.getAsFile()
      if (file) {
        this.uploadFile(file)
      }
    })
    
    // Handle any text in the clipboard
    const text = event.clipboardData.getData('text/plain')
    if (text && !imageItems.length) {
      // If there's only text and no images, let Trix handle it naturally
      // by not preventing default above
    }
  }

  uploadFile(file) {
    // Get CSRF token for the upload
    const csrfToken = document.querySelector('meta[name="csrf-token"]').getAttribute('content')
    
    // Create a unique file name
    const uniqueId = new Date().getTime()
    const fileName = uniqueId + '-' + file.name
    
    // Get direct upload URL from your Rails app
    const url = this.getDirectUploadUrl()
    
    // Create a new DirectUpload instance
    const upload = new DirectUpload(
      file, 
      url, 
      {
        headers: {
          'X-CSRF-Token': csrfToken
        }
      }
    )

    // Upload the file
    upload.create((error, blob) => {
      if (error) {
        console.error('Error uploading file:', error)
      } else {
        // Insert the image into the Trix editor
        this.insertImageIntoEditor(blob)
      }
    })
  }

  getDirectUploadUrl() {
    // Get the direct upload URL from a data attribute or use the default Rails path
    return this.data.get('uploadUrl') || '/rails/active_storage/direct_uploads'
  }

  insertImageIntoEditor(blob) {
    // Get the Trix editor's attachment manager
    const attachment = new Trix.Attachment({
      content: this.createImageElement(blob),
      contentType: blob.content_type,
      sgid: blob.signed_id
    })
    
    // Get the Trix editor instance
    const editor = this.trixElement.editor
    
    // Insert the attachment at the current cursor position
    editor.insertAttachment(attachment)
    
    // Move cursor to end of the inserted attachment
    editor.composition.setSelectedRange([editor.getPosition() + 1, editor.getPosition() + 1])
  }

  createImageElement(blob) {
    // Create an image element with the blob's signed URL
    const img = document.createElement('img')
    img.src = this.createSignedBlobUrl(blob)
    img.classList.add('trix-attachment-image')
    return img
  }

  createSignedBlobUrl(blob) {
    // Create a URL for displaying the image using ActiveStorage's blob URL
    const publicUrl = `/rails/active_storage/blobs/redirect/${blob.signed_id}/${blob.filename}`
    return publicUrl
  }
}