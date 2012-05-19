def given_i_am_on_a_conversation_page_with_a_contribution
  contribution = FactoryGirl.create :contribution
  conversation_page = ConversationsPage.new(page)
  conversation_page.visit_conversations(contribution.conversation)
end

def when_i_report_the_contribution

end

def then_the_contribution_is_flagged_for_moderation

end

def then_the_page_has_a_report_abuse_link
  page.should have_link("Alert us.")
end
