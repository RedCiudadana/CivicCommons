class PasswordsController < Devise::PasswordsController
  
  before_filter :require_ssl, :only => [:new, :create]
  skip_before_filter :require_no_ssl

  # POST /resource/password
  def create
    self.resource = resource_class.send_reset_password_instructions(params[resource_name])

    if resource.facebook_authenticated?
      @fb_auth_forgot_password = true
      
      # resets the resource, as new instance
      build_resource({})
      
      render_with_scope :new
    elsif resource.errors.empty?
      set_flash_message :notice, :send_instructions
      redirect_to new_session_path(resource_name)
    else
      render_with_scope :new
    end
  end
  
  def fb_auth_forgot_password
    render :layout => false
  end
end