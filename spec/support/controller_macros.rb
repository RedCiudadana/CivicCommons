module ControllerMacros
  def login_admin
    @request.env["devise.mapping"] = Devise.mappings[:admin]
    @user = Factory.create(:admin)
    sign_in @user
  end

  def login_user
    setup_person
    @user = Factory.create(:registered_user)
    sign_in @user
  end

  def setup_person
    @request.env["devise.mapping"] = Devise.mappings[:person]
  end
end