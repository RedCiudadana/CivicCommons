module UserProfileDSL

  def user_profile_page
    return UserProfilePage.new page
  end

  def visit_user_profile_for(user)
    user_profile_page.visit_user user
  end

  def activity_stream
    page.find '.activity-stream'
  end

end

class UserProfilePage < PageObject

  def visit_user(user)
    visit user_path(user)
  end
end

Rspec.configuration.include UserProfileDSL, :type => :acceptance
