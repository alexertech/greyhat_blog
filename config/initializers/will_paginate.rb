# frozen_string_literal: true

require 'will_paginate/view_helpers/action_view'

if defined?(WillPaginate::ActionView)
  module WillPaginate
    module ActionView
      def will_paginate(collection = nil, options = {})
        options = {
          :renderer => BootstrapRenderer,
          :previous_label => '←',
          :next_label => '→',
          :class => 'pagination'
        }.merge(options)

        super(collection, options)
      end

      class BootstrapRenderer < LinkRenderer
        def container_attributes
          {class: "pagination"}
        end

        def page_number(page)
          if page == current_page
            tag(:li, tag(:span, page, class: 'page-link'), class: 'page-item active')
          else
            tag(:li, link(page, page, class: 'page-link', rel: rel_value(page)), class: 'page-item')
          end
        end

        def gap
          tag(:li, tag(:span, '&hellip;', class: 'page-link'), class: 'page-item disabled')
        end

        def previous_page
          num = @collection.current_page > 1 && @collection.current_page - 1
          previous_or_next_page(num, @options[:previous_label], 'page-item')
        end

        def next_page
          num = @collection.current_page < total_pages && @collection.current_page + 1
          previous_or_next_page(num, @options[:next_label], 'page-item')
        end

        def previous_or_next_page(page, text, classname)
          if page
            tag(:li, link(text, page, class: 'page-link'), class: classname)
          else
            tag(:li, tag(:span, text, class: 'page-link'), class: "#{classname} disabled")
          end
        end
      end
    end
  end
end 