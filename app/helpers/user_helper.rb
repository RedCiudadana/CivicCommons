module UserHelper

  def classes(contribution)
    cls = ''

    if contribution.is_image? or contribution.embedly_type == 'image'
      cls = 'image dnld'
    elsif contribution.embedly_type == 'video'
      cls = 'video dnld'
    elsif contribution.has_attachment?
      cls = 'document dnld'
    elsif contribution.has_media?
      cls = 'link dnld'
    end

    return cls
  end

  def avatar_label_text
    if @person.is_organization?
      "Company Logo"
    else
      "Your Photograph"
    end
  end

  def bio_label_text
    if @person.is_organization?
      "Tell us about your company"
    else
      "Tell us a little about yourself"
    end
  end

  def current_image_label_text
    if @person.is_organization?
      "Current Logo"
    else
      "Current Photograph"
    end
  end

  def name_label_text
    if @person.is_organization?
      "Name of Organization"
    else
      "Your Name"
    end
  end
  
  def title_label_text
    "Your Title" if !@person.is_organization?
  end

  def remove_avatar_text
    if @person.is_organization?
      "Remove Logo"
    else
      "Remove Photograph"
    end
  end

  def remote_url(url)
    url.gsub(/www\./, 'http://www.')
  end

  def url_to_contribution(contribution)
    if contribution.issue && ! ( controller.controller_name == 'issues' && controller.action_name == 'show' )
      issue_node_url( contribution )
    elsif contribution.conversation
      conversation_node_url( contribution )
    end
  end

end
