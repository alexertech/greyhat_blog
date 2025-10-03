# frozen_string_literal: true

namespace :action_text do
  desc "Regenerate all ActionText attachment SGIDs with current secret_key_base"
  task regenerate_sgids: :environment do
    puts "Starting SGID regeneration for ActionText attachments..."

    fixed_count = 0
    error_count = 0

    ActionText::RichText.find_each do |rich_text|
      begin
        # Get the raw HTML body
        html = rich_text.body.to_s

        # Find all action-text-attachment tags with sgid attributes
        modified = false
        new_html = html.gsub(/<action-text-attachment\s+sgid="[^"]*"[^>]*>/) do |tag|
          # Extract the filename from the tag
          filename = tag.match(/filename="([^"]+)"/)[1] rescue nil

          if filename
            # Find the blob by filename
            blob = ActiveStorage::Blob.find_by(filename: filename)

            if blob
              # Generate new SGID and signed URL
              new_sgid = blob.attachable_sgid
              new_url_token = blob.signed_id(purpose: :blob_id)

              # Rebuild the tag with new tokens
              new_tag = tag.gsub(/sgid="[^"]*"/, "sgid=\"#{new_sgid}\"")
              new_tag = new_tag.gsub(/url="[^"]*"/) do |url_match|
                # Keep the base URL structure but replace the token
                if url_match =~ /blobs\/redirect\/[^\/]+\//
                  url_match.gsub(/blobs\/redirect\/[^\/]+\//, "blobs/redirect/#{new_url_token}/")
                else
                  url_match
                end
              end

              modified = true
              puts "  ✓ Fixed: #{filename}"
              new_tag
            else
              puts "  ✗ Blob not found for: #{filename}"
              tag
            end
          else
            puts "  ⚠ No filename found in tag"
            tag
          end
        end

        if modified
          # Update the rich text body
          rich_text.update_column(:body, new_html)
          fixed_count += 1
          puts "✓ Updated #{rich_text.record_type} ##{rich_text.record_id}"
        end

      rescue => e
        error_count += 1
        puts "✗ Error processing #{rich_text.record_type} ##{rich_text.record_id}: #{e.message}"
        puts e.backtrace.first(3)
      end
    end

    puts "\n" + "="*50
    puts "SGID Regeneration Complete!"
    puts "Fixed: #{fixed_count} records"
    puts "Errors: #{error_count} records"
    puts "="*50
  end
end
