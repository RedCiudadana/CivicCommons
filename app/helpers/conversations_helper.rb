module ConversationsHelper

  def opportunity_navigation_item_selected?(type)
    type == controller.controller_name
  end

  def format_rating(contribution)
    return "" unless contribution.total_rating
    out = contribution.total_rating > 0 ? "+" : ""
    out += contribution.total_rating.to_s
  end

  def format_user_rating(value)
    return case value
    when 1
      "You found this productive"
    else
      "You found this unproductive"
    end
  end

  def format_time(t)
     return "no particular time" if t.nil?
     return t.localtime.strftime("%c")
  end

  def format_time_only(t)
    return t.localtime.strftime("%l:%M %p") unless t.nil?
  end

  def format_date(t)
    t.localtime.strftime("%b %e, %G") unless t.blank?
  end

  def contribution_action_past_tense(contribution)
    if contribution.comment_only?
      action = 'commented'
    elsif contribution.has_attachment?
      action = 'shared a file'
    elsif contribution.has_media?
      action = 'shared a link'
    else
      action = 'shared a file and a link'
    end

    if not contribution.blank?
      case contribution.embedly_type
      when "image"
        type = "image"
      when "video"
        type = "video"
      when "audio"
        type = "audio"
      when "ppt"
        type = "presentation"
      when "photo"
        type = "photo"
      else
        type = nil
      end
      action.sub!('link', type) unless type.nil?
    end

    return action
  end

  def contribution_form_placeholder_text_for(type, subtype = nil)
    case type
    when :comment
      "Leave a Comment..."
    when :question
      "Ask a Question..."
    when :answer

    when :attached_file
      "Comment on file..."
    when :embedded_snippet
      "Comment on video..."
    when :link
      "Comment on link..."
    when :suggested_action
      "Suggest an action..."
    when :embedly_contribution
      if subtype == :video
        "Share a video..."
      else
        "Share a link..."
      end
    else
      ""
    end
  end

  # This method allows you to get the subset of direct descendents of this_contribution_id from the complete thread of root_contribution_and_descendents
  #  root_contribution in this case is a TopLevelContribution node, and the whole thing has already been loaded by the controller,
  #  so we don't want to poll the database for each subset when we've already loaded the entire set once.
  def display_direct_descendant_subset(contribution_descendants, this_contribution_id, ratings=nil)
    out = ""
    ratings = ratings || RatingGroup.ratings_for_conversation_by_contribution_with_count(Contribution.find(this_contribution_id).conversation, current_person)
    return out unless contribution_descendants
    contribution_descendants.select{ |c| c.parent_id == this_contribution_id }.sort_by{ |c| c.created_at }.each do |contribution|
      out += render(:partial => "conversations/threaded_contribution_template", :locals => { :contribution => contribution, :ratings => ratings })
    end
    raw(out)
  end

  def conversation_node_path(contribution)
    conversation_path(contribution.conversation, anchor: "node-#{contribution.id}")
  end

  def conversation_node_url(contribution, options = {})
    options ||= {}
    if Hash === options
      options[:anchor] ||= "node-#{contribution.id}"
    end
    conversation_url(contribution.conversation, options)
  end

  def filter_title(filter, suffix = nil)
    case filter.to_sym
    when :active
      title = "Most Active"
    when :recommended
      title = "Recommended"
    when :popular
      title = "Most Popular"
    when :recent
      title = "Newest"
    else
      title = "Filtered"
    end

    if suffix then title += suffix end

    title
  end

  def filter_description(filter)
    case filter.to_sym
    when :active
      "These are conversations that are inspiring people to join in."
    when :recommended
      "These are conversations we think you should check out because they're important and inspiring."
    when :popular
      "These are the conversations that are sparking interest."
    when :recent
      "These are the conversations that are just getting started."
    else
      "These are the conversations that match your filter."
    end
  end

  def path_to_content_item(content_item)
    if content_item.content_type == 'RadioShow'
      path = radioshow_path(content_item)
    elsif content_item.content_type == 'BlogPost'
      path = blog_path(content_item)
    end
    return path
  end

  def rating_buttons(contribution, ratings_hash)
    out = []
    RatingGroup.cached_rating_descriptors.each do |id, title|
      if current_person && current_person.id == contribution.owner
        out << "<span class='rating-button'>#{title} <span class='number'>#{ratings_hash[contribution.id][title][:total]}</span></span>"
      else
        out << link_to( "#{title} <span class='loading'>#{image_tag 'loading.gif'}</span><span class='number'>#{ratings_hash[contribution.id][title][:total]}</span>".html_safe, conversation_contribution_toggle_rating_path(:contribution_id => contribution, :rating_descriptor_title => title), :remote => true, :method => :post, :id => "contribution-#{contribution.id}-rating-#{title}", :class => "rating-button #{'active' if ratings_hash[contribution.id][title][:person]}" )
      end
    end
    raw(out.join(' '))
  end

  def format_comment(contribution)
    text = contribution.content.gsub(/([^\n]\n)(?=[^\n])/, ' ')

    # remove double paragraph tags which ocurr since TinyMCE creates paragraph tags by default and so does simple_format. Since old contribitions
    # do not have the paragraph tags for all text and we don't want to update them so that they do, we remove double p tags from output
    stripped_extra_paragraphs = simple_format(text).gsub(/\<p\>\<p\>/, '<p>').gsub(/\<\/p\>\<\/p\>/, '</p>')
    sanitize(auto_link(stripped_extra_paragraphs))
  end

  def respond_button_text(contribution)
    current_person && contribution.person == current_person ? "Add More" : "Respond#{' to ' + contribution.person.short_name if contribution.person}"
  end

  def setup_conversation(conversation)
    conversation.tap do |conversation|
      conversation.contributions.build if conversation.contributions.empty?
    end
  end

  def get_path_sym(content_item)
    if content_item
      case content_item.content_type
      when 'RadioShow'
        :radioshow
      when 'BlogPost'
        :blog
      end
    end
  end

end
