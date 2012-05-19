module BlogHelper

  def format_publish_date(date)
    date = date.published if date.is_a? ContentItem
    return date.strftime('%A, %B %d, %Y')
  end

  def blog_filter_by_author_link(author,current_author)
    if author == current_author
      path = blog_index_path(request.parameters.merge({:author_id => nil, :page => nil}))
    else
      path = blog_index_path(request.parameters.merge({:author_id => author.id, :page => nil}))
    end
    link_to raw("#{profile_image(author,16,  'mem-img')}<span>#{author.name}</span>"), path , :class => "#{'active' if current_author.try(:id) == author.id}"
  end
end
