def given_a_user
  a_user = Factory.create(:normal_person)
end

def when_I_visit_the_users_profile
  user_profile_page.visit_user(a_user)
end

def then_I_should_see_they_are_just_getting_started_in_their_recent_activity_stream
  user_profile_page.should contain("#{a_user.name} is just getting started")
end