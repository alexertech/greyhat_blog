# frozen_string_literal: true

module SeoHelper
  def structured_data_for_post(post)
    data = {
      "@context" => "https://schema.org",
      "@type" => "BlogPosting",
      "headline" => post.title,
      "description" => strip_tags(post.body.to_plain_text).truncate(160),
      "author" => {
        "@type" => "Person",
        "name" => post.user.display_name || post.user.email.split('@').first,
        "description" => post.user.description || "Autor en Greyhat"
      },
      "publisher" => {
        "@type" => "Organization",
        "name" => "Greyhat",
        "url" => root_url,
        "logo" => {
          "@type" => "ImageObject",
          "url" => asset_url('logo.png')
        }
      },
      "datePublished" => post.created_at.iso8601,
      "dateModified" => post.updated_at.iso8601,
      "mainEntityOfPage" => {
        "@type" => "WebPage",
        "@id" => post_url(post)
      },
      "url" => post_url(post),
      "wordCount" => post.body.to_plain_text.split.size,
      "timeRequired" => "PT#{((post.body.to_plain_text.split.size/200)+1)}M",
      "inLanguage" => "es-ES",
      "articleSection" => "Technology"
    }
    
    # Add image if present
    if post.image.attached?
      data["image"] = {
        "@type" => "ImageObject",
        "url" => url_for(post.image.variant(:banner)),
        "width" => 1536,
        "height" => 474
      }
    end
    
    # Add tags as keywords
    if post.tags.any?
      data["keywords"] = post.tags.pluck(:name).join(", ")
      data["about"] = post.tags.map do |tag|
        {
          "@type" => "Thing",
          "name" => tag.name
        }
      end
    end
    
    # Add interaction data if available
    data["interactionStatistic"] = [
      {
        "@type" => "InteractionCounter", 
        "interactionType" => "https://schema.org/ReadAction",
        "userInteractionCount" => post.visits_count || 0
      },
      {
        "@type" => "InteractionCounter",
        "interactionType" => "https://schema.org/CommentAction", 
        "userInteractionCount" => post.comments.approved.count
      }
    ]
    
    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end
  
  def structured_data_for_website
    data = {
      "@context" => "https://schema.org",
      "@type" => "WebSite",
      "name" => "Greyhat",
      "description" => "Explorando el Equilibrio entre la Tecnología y la Vida",
      "url" => root_url,
      "potentialAction" => {
        "@type" => "SearchAction",
        "target" => {
          "@type" => "EntryPoint",
          "urlTemplate" => "#{search_url}?q={search_term_string}"
        },
        "query-input" => "required name=search_term_string"
      },
      "sameAs" => [
        # Add social media URLs here when available
      ],
      "inLanguage" => "es-ES"
    }
    
    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end
  
  def structured_data_for_organization
    data = {
      "@context" => "https://schema.org",
      "@type" => "Organization",
      "name" => "Greyhat",
      "description" => "Blog de tecnología enfocado en el equilibrio entre la tecnología y la vida",
      "url" => root_url,
      "logo" => asset_url('logo.png'),
      "foundingDate" => "2024",
      "knowsAbout" => [
        "Tecnología",
        "Desarrollo Web", 
        "Inteligencia Artificial",
        "Equilibrio Digital",
        "Productividad"
      ]
    }
    
    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end
  
  def page_title(title = nil)
    if title.present?
      "#{title} - Greyhat"
    else
      "Greyhat - Explorando el Equilibrio entre la Tecnología y la Vida"
    end
  end
  
  def meta_description(description = nil)
    description.presence || "Blog de tecnología enfocado en encontrar el equilibrio perfecto entre la innovación digital y una vida plena. Reflexiones, consejos y herramientas para profesionales tech."
  end
  
  def canonical_url(url = nil)
    url || request.original_url.split('?').first
  end
  
  def breadcrumb_structured_data(items)
    data = {
      "@context" => "https://schema.org",
      "@type" => "BreadcrumbList",
      "itemListElement" => items.map.with_index do |item, index|
        {
          "@type" => "ListItem",
          "position" => index + 1,
          "name" => item[:name],
          "item" => item[:url]
        }
      end
    }
    
    content_tag(:script, data.to_json.html_safe, type: "application/ld+json")
  end
end