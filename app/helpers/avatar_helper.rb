module AvatarHelper

  # Create Avatar and Link for a Users Profile
  def user_profile(person)
    if person
      person = Person.find(person) if person.is_a?(Numeric)
      link_to_profile(person) do
        loggedin_image(person)
      end
    else
      loggedout_image
    end
  end

  def text_profile(person)
    if person
      person = Person.find(person) if person.is_a?(Numeric)
      link_to_profile(person) do
        person.name
      end
    end
  end

  def member_profile(person, css_class='callout')
    avatar_profile(person, 40, css_class)
  end

  def conversation_profile(person, css_class='callout')
    avatar_profile(person, 40, css_class)
  end

  def contribution_profile(person, css_class='callout')
    avatar_profile(person, 40, css_class)
  end

  def featured_profile(person, css_class='callout')
    avatar_profile(person, 50, css_class)
  end

  # Profile's Avatar Image with name as alt text
  def profile_image(person, size=20, css_class='callout')
    if person.avatar_image_url.nil?
      nil
    else
      image_tag person.avatar_image_url, alt: person.name, height: size, width: size, title: person.name, class: css_class
    end
  end

  def loggedin_image(person, size=40, css_class='callout')
    profile_image(person, size, css_class)
  end

  def loggedout_image(size=40, css_class='callout')
    image_tag "avatar_#{size}.gif", alt: 'default avatar', class: css_class, height: size, width: size
  end

  def avatar_profile(person, size=20, css_class='callout')
    if person
      person = Person.find(person) if person.is_a?(Numeric)
      link_to_profile(person) do
        profile_image(person, size, css_class)
      end
    end
  end

  def link_to_profile(person)
    link_to yield, user_url(person), title: person.name
  end

  def link_to_settings(person, css_class='user-link')
    link_to "Settings", secure_edit_user_url(person), title: "Profile Settings", class: css_class
  end

  # Creates an image_tag for a particular person
  # options includes options passed along to image_tag along with
  # :style_name which is a directive for paperclip which determines the
  # ':style' paperclip should use for the image.
  #
  def avatar_tag(person, options={})
    style_name = options.delete(:style_name) || :small
    url = person.avatar.url(style_name)
    if request.ssl? then url = url.gsub(/http:/i, 'https:') end
    image_options = {
      :width => 50,
      :height => 50,
      :alt => "avatar",
      :title => person.name}.merge(options)
    image_tag(url, image_options)
  end

end
