class AuthenticationController < ApplicationController
  skip_before_filter :require_no_ssl
  before_filter :require_user, :except => [:registering_email_taken]
  before_filter :require_facebook_authenticated, :only => [:before_facebook_unlinking,:confirm_facebook_unlinking, :process_facebook_unlinking]
  layout :set_layout, :only => [:before_facebook_unlinking, :confirm_facebook_unlinking, :process_facebook_unlinking]

  def before_facebook_unlinking
    @person = current_person
  end

  def confirm_facebook_unlinking
  end

  def conflicting_email
    render :layout => false
  end

  def decline_fb_auth
    if current_person.update_attribute(:declined_fb_auth, true)
      render :nothing => true, :status => :ok
    else
      render :text => current_person.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def process_facebook_unlinking
    @person = current_person
    @person.unlink_from_facebook(params[:person])
    if @person.valid?
      sign_in @person, :event => :authentication, :bypass => true
      render :template => '/authentication/fb_unlinking_success.html'
    else
      render :template => '/authentication/before_facebook_unlinking.html'
    end
  end

  def registering_email_taken
    render :layout => false
  end

  def successful_registration
    render :layout => false
  end

  def update_conflicting_email
    if !session[:other_email].blank? && current_person.update_attribute(:email, session[:other_email]) 
      session[:other_email] = nil
      render :nothing => true, :status => :ok
    else
      render :text => current_person.errors.full_messages, :status => :unprocessable_entity
    end
  end

  def fb_linking_success
    render :layout => false
  end

protected

  def set_layout
    request.xhr? ? 'content_for/main_body' : 'application'
  end

  def require_facebook_authenticated
    unless current_person.facebook_authenticated?
      render :text => '<p>Your account needs to have been connected to Facebook in order to do this.</p>' 
      return false
    end
  end
end
