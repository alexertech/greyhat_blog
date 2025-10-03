# frozen_string_literal: true

module PostsHelper
  # Constants for reading time calculation
  WORDS_PER_MINUTE = 200

  # Calculate estimated reading time for a post
  # @param post [Post] The post to calculate reading time for
  # @return [Integer] Estimated reading time in minutes
  def reading_time(post)
    return 1 if post.body.blank?

    word_count = post.body.to_plain_text.split.size
    ((word_count.to_f / WORDS_PER_MINUTE).ceil).clamp(1, Float::INFINITY).to_i
  end

  # Format reading time for display
  # @param post [Post] The post to format reading time for
  # @return [String] Formatted reading time string
  def reading_time_text(post)
    minutes = reading_time(post)
    "#{minutes} min de lectura"
  end
end
