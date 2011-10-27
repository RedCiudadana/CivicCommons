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

class Person

  def create_conversation(options)
    Factory.create(:user_generated_conversation, {:owner => self}.merge(options))
  end

  def create_comment(options)
    Factory.create(:comment, {:person => self}.merge(options))
  end

  def responds_to_comment(options)

  end

end
Rspec.configuration.include UserProfileDSL, :type => :acceptance
