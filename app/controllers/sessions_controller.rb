class SessionsController < Devise::SessionsController

  prepend_before_filter :require_no_authentication, :only => [:new, :create, :ajax_new, :ajax_create]
  prepend_before_filter :allow_params_authentication!, :only => [:create, :ajax_create]
  before_filter :require_ssl, :only => [:new, :create]
  skip_before_filter :require_no_ssl

  def new
    super
    if RedirectHelper.valid?(request.headers['Referer'])
      session[:previous] = request.headers['Referer']
    end
  end

  def create
    super
    session[:previous] = nil
  end

  def ajax_new
    session[:close_modal_on_exit] = true
    session[:previous] = request.headers['Referer'] if RedirectHelper.valid?(request.headers['Referer'])
    render :partial => 'sessions/new', :layout => false
  end

  # POST /resource/ajax_login
  def ajax_create
    resource = warden.authenticate!(:scope => resource_name, :recall => "#{controller_path}#new")
    sign_in(resource_name, resource)
    if session.has_key?(:close_modal_on_exit) and session[:close_modal_on_exit]
      @notice = "You have successfully logged in."
      respond_to do |format|
        format.js {render :partial => 'sessions/close_modal_on_exit', :layout => false}
        format.html do 
          redirect_to session[:previous] || root_path
          session[:previous] = nil
        end
      end
    else
      render :action => :new
    end
  end

end
