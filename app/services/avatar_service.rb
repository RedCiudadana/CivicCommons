require 'digest'
require 'net/http'
require 'uri'

class AvatarService

  def self.avatar_image_url(person, options={})
    request = options.delete(:request)
    if request.present?
      base_url = "#{request.protocol}#{request.host_with_port}"
    else
      base_url = nil
    end
    # Image displayed by order of priority
    # 1. image uploaded
    return person.avatar.url(:standard) if person.avatar?
    # 2. facebook
    return self.facebook_image_url(person) if person.authentications.present?
    # 3. twitter
    return self.twitter_image_url(person) if person.twitter_username.present?
    # 4. gravatar
    return self.gravatar_image_url(person) if self.gravatar_available?(person)
    # 5. default - need to be absolute path, due to widget
    "#{base_url}#{person.avatar.url(:standard)}"
  end

  def self.facebook_image_url(person)
    facebook_id = person.authentications.first.uid
    "https://graph.facebook.com/#{facebook_id}/picture"
  end

  def self.twitter_image_url(person)
    "http://api.twitter.com/1/users/profile_image/#{person.twitter_username}"
  end

  def self.gravatar_available?(person)
    gravatar_response = Net::HTTP.get_response(URI.parse(gravatar_image_url(person)))

    unless gravatar_response.class == Net::HTTPNotFound
      true
    else
      false
    end
  end

  def self.gravatar_image_url(person)
    hashed_email = self.create_email_hash(person)
    "http://gravatar.com/avatar/#{hashed_email}?d=404"
  end

  def self.create_email_hash(person)
    Digest::MD5.hexdigest(person.email)
  end

  # Update an entities avatar url
  def self.update_avatar_url_for(person)
    avatar_image = avatar_image_url(person)
    Person.update_all({avatar_url: avatar_image, avatar_cached_image_url: avatar_image}, {id: person.id})
  end

end
