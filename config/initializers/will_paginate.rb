# frozen_string_literal: true

if defined?(WillPaginate)
  module WillPaginate
    module ActionView
      def will_paginate(collection = nil, options = {})
        options[:renderer] ||= BootstrapRenderer
        super(collection, options)
      end

      class BootstrapRenderer < LinkRenderer
        def container_attributes
          {class: "pagination #{@options[:class]}"}
        end

        def page_number(page)
          if page == current_page
            tag(:li, tag(:span, page, class: 'page-link'), class: 'page-item active')
          else
            tag(:li, link(page, page, class: 'page-link', rel: rel_value(page)), class: 'page-item')
          end
        end

        def previous_or_next_page(page, text, classname)
          if page
            tag(:li, link(text, page, class: 'page-link'), class: 'page-item')
          else
            tag(:li, tag(:span, text, class: 'page-link'), class: 'page-item disabled')
          end
        end

        def gap
          tag(:li, tag(:span, '&hellip;'.html_safe, class: 'page-link'), class: 'page-item disabled')
        end

        def html_container(html)
          tag(:ul, html, container_attributes)
        end
      end
    end
  end
end 