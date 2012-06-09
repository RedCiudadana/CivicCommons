module CivicCommonsDriver
  module Pages
    class Actions
      SHORT_NAME = :actions
      include Page
      has_link :suggest_an_action, 'Suggest an Action', :actions
      has_link :write_a_petition, 'Write a Petition', :new_petition
      has_link :take_a_vote, 'Create a Vote', :new_opportunity_vote
      has_link_for :edit_petition, 'Edit', :edit_petition
      has_link_for :delete_petition, 'Delete', :actions
    end
  end
end
