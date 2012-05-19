require File.expand_path(File.dirname(__FILE__) + '/acceptance_helper')

feature "Unlink Account From Facebook", %q{
  In order to not participate using Facebook anymore
  As a current user who have already connected to Facebook
  I want to unlink my account
} do
  include Facebookable
  before do
    stub_facebook_auth
  end

  scenario "Unlinking process", :js=>true do
    login_as :registered_user_with_facebook_authentication
    goto :edit_profile_page, :for=>logged_in_user
    Notifier.deliveries  = []
    unlink_from_facebook email: "johnd-new-email@example.com"
    unlink_success_modal.should be_visible
    Notifier.deliveries.length.should == 1
    Notifier.deliveries.first.to.should have_content 'johnd@example.com'
    Notifier.deliveries.first.to.should have_content 'johnd-new-email@example.com'
    Notifier.deliveries.first.subject.should have_content "You've recently changed your email with The Civic Commons"
  end

  scenario "Should throw validation error when user does not enter password", :js=>true do
    login_as :registered_user_with_facebook_authentication
    goto :edit_profile_page, :for => logged_in_user
    begin_unlinking_from_facebook
    click_submit_invalid_form_button
    current_page.should have_password_required_error
  end
  def unlink_from_facebook options
    begin_unlinking_from_facebook
    fill_in_email_with options[:email]
    fill_in_password_with "password123"
    fill_in_confirm_password_with "password123"
    click_submit_button
  end
  def begin_unlinking_from_facebook
    follow_unlink_from_facebook_link
    wait_until { confirm_unlink_from_facebook_link.visible? }
    follow_confirm_unlink_from_facebook_link
  end
  def unlink_success_modal
    page.find ".fb-auth.unlinking-success.fb-modal"
  end
end
