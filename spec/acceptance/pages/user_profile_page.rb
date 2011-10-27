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

  def create_conversation(options={})
    Factory.create(:user_generated_conversation, {:owner => self}.merge(options))
  end

  def create_comment(options={})
    Factory.create(:comment, {:person => self}.merge(options))
  end

  def responds_to_comment(options={})
    if options[:parent_comment].blank?
      parent_person = Factory.create(:normal_person)
      parent_comment = parent_person.create_comment
    else
      parent_comment = options[:parent_comment]
    end
    my_comment = self.create_comment({:parent => parent_comment, :conversation => parent_comment.conversation}.merge( options.delete_if{|key,value| key == :parent_comment}))

    return parent_comment, my_comment
  end

end
Rspec.configuration.include UserProfileDSL, :type => :acceptance
