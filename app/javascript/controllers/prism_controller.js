import { Controller } from "@hotwired/stimulus"

// Connects to data-controller="prism"
export default class extends Controller {
  connect() {
    // Asegurarse de que Prism esté disponible
    if (typeof Prism === 'undefined') {
      console.error('Prism.js no está disponible');
      return;
    }

    // Procesar bloques de código en el contenido del post
    this.processCodeBlocks();
    
    // Ejecutar highlight después del procesamiento
    Prism.highlightAll();
  }

  processCodeBlocks() {
    const contentContainer = document.querySelector('.trix-content');
    if (!contentContainer) return;

    const preElements = contentContainer.querySelectorAll('pre');
    
    preElements.forEach((preElement) => {
      // Regex para capturar lang-xxx al final del texto
      const regex = /\s*lang-(\w+)\s*$/;
      
      // Verificar si ya tiene un elemento code interno
      if (preElement.querySelector('code')) return;
      
      const textContent = preElement.textContent || '';
      const match = textContent.match(regex);
      
      if (match) {
        const language = match[1]; // javascript, python, etc.
        
        // Crear elemento code
        const codeElement = document.createElement('code');
        
        // Remover la declaración de lenguaje del texto
        const cleanText = textContent.replace(regex, '').trim();
        
        // Establecer el contenido limpio
        codeElement.textContent = cleanText;
        
        // Agregar clases de Prism
        codeElement.classList.add(`language-${language}`);
        preElement.classList.add(`language-${language}`);
        
        // Limpiar el pre y agregar el code
        preElement.innerHTML = '';
        preElement.appendChild(codeElement);
      }
    });
  }
}
