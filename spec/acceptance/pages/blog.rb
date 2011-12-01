module CivicCommonsDriver
  module Pages
    class Blog
      SHORT_NAME = :blog
      include Page
      
      def follow_the_blog_post_link_for blog_post
        click_link blog_post.title
        set_current_page_to :blog_post
      end
      
      class Show
        SHORT_NAME = :blog_post
        include Page
        
        has_link :show_add_file_field, "contribution-add-file"
        has_file_field :contribution_attachment, "conversation[contributions_attributes][0][attachment]"
        has_button :start_invalid_conversation, "Start My Conversation"
        
        def add_contribution_attachment
          follow_show_add_file_field_link
          attach_contribution_attachment_with_file File.join(attachments_path, 'imageAttachment.png')
        end
        
        def has_an_error_for? field
          case field
          when :invalid_link
            error_msg = "The link you provided is invalid"
          when :attachment_needs_comment
            error_msg = 'Sorry! You must also write a comment above when you upload a file.'
          end 
          has_content? error_msg
        end
        
      end
      
    end
  end
end
