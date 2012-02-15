def path_to_url(path)
    "#{request.protocol}#{request.host_with_port}/#{path.sub(%r[^/],'')}"
end



xml.instruct! :xml, :version => "1.0"
xml.rss :version => "2.0", 'xmlns:atom' => "http://www.w3.org/2005/Atom" do
  xml.channel do
    xml.tag!('atom:link', :href => user_url(@user, :format => :xml), :rel => "self", :type => "application/rss+xml")
    xml.title "The Civic Commons: #{@user.name}"
    xml.description "Bio: #{@user.bio}"
    xml.copyright "(c) Copyright #{Date.today.strftime('%Y')} The Civic Commons"
    xml.link user_url(@user)
    xml.image do
      xml.url @user.avatar_url
      xml.title "The Civic Commons: #{@user.name}"
      xml.link user_url(@user)
    end
    xml.language "en-us"
    xml.pubDate Time.now.rfc822
    xml.lastBuildDate Time.now.rfc822

    @user.all_recent_activity.each do |recent_item|

      xml.item do
        if recent_item.kind_of? Conversation
          xml.title recent_item.title
          xml.link conversation_url(recent_item)
          xml.guid conversation_url(recent_item)
          xml.description recent_item.summary

        elsif recent_item.kind_of? RatingGroup
          contribution = recent_item.contribution
          contribution.conversation = recent_item.conversation

          xml.title "#{recent_item.person.name} rated a response as #{Rating.find_by_rating_group_id(recent_item.id).rating_descriptor.title} on the conversation '#{recent_item.conversation.title}'"
          xml.link path_to_url conversation_node_path(contribution)
          xml.guid path_to_url conversation_node_path(contribution)

        elsif recent_item.kind_of? Contribution
          recent_item = ContributionPresenter.new(recent_item)
          xml.title "#{@user.name} responded to the #{recent_item.parent_type} '#{recent_item.parent_title}'"
          xml.link path_to_url recent_item.node_path
          xml.guid path_to_url recent_item.node_path
          xml.description Sanitize.clean(recent_item.content, :remove_contents => ['script']).strip

        else
          xml.title "#{@user.name} participated in a conversation at The Civic Commons"
          xml.link user_url(@user)
          xml.guid user_url(@user)
          xml.description "#{@user.name} participated in a conversation at The Civic Commons"
        end

        xml.pubDate recent_item.created_at.to_time.to_formatted_s(:rfc822)
      end
    end
  end
end
