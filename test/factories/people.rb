FactoryGirl.define do |f|
  factory :invalid_person, :class=>Person do |u|
    u.first_name ''
    u.last_name ''
    u.zip_code '44313'
    u.password 'password'
    u.email ''
    u.avatar_cached_image_url '/images/avatar.jpg'
  end

  factory :normal_person, :class=>Person do |u|
    u.first_name 'John'
    u.title 'staff at CivicCommons'
    u.last_name 'Doe'
    u.zip_code '44313'
    u.password 'password'
    u.sequence(:email) {|n| "test.account#{n}@mysite.com" }
    u.daily_digest false
    u.avatar_url '/images/avatar_70.gif'
    u.avatar_cached_image_url '/images/avatar.jpg'
  end

  factory :proxy_person, :parent => :normal_person do |u|
    u.proxy true
  end

  factory :registered_user, :parent => :normal_person do |u|
    u.confirmed_at { Time.now }
    u.declined_fb_auth true
  end

  factory :sequence_user, :parent => :registered_user do |u|
    u.sequence(:id)
  end

  factory :person_subscribed_to_weekly_newsletter, :parent => :registered_user do |u|
    u.weekly_newsletter true
  end

  factory :person_subscribed_to_daily_digest, :parent => :registered_user do |u|
    u.daily_digest true
  end

  factory :registered_user_with_avatar, :parent => :registered_user do |u|
    u.avatar File.new(Rails.root + 'test/fixtures/images/test_image.jpg')
  end

  factory :person, :parent => :registered_user do | u |
    u
  end
  factory :registered_user_who_hasnt_declined_fb, :parent => :registered_user do | u| 
    u.declined_fb_auth false
  end
  factory :registered_user_with_conflicting_facebook_email, :parent => :registered_user do | u |
    u.email 'johnd-conflicting-email@example.com'
  end

  factory :registered_user_with_facebook_email, :parent => :registered_user do | u |
    u.email 'johnd@example.com'
  end
  factory :registered_user_with_facebook_authentication, :parent => :registered_user_with_facebook_email do |u|
    after_create { | u |
      u.link_with_facebook(FactoryGirl.create :facebook_authentication, person: u )
    }
  end
  factory :admin_person, :parent => :registered_user do |u|
    u.password 'password'
    u.sequence(:email) {|n| "test.admin.account#{n}@mysite.com" }
    u.sequence(:last_name) {|n| "Doe #{n}" }
    u.admin true
    u.confirmed_at '2011-03-04 15:33:33'
  end

  factory :admin, :parent => :admin_person

end
