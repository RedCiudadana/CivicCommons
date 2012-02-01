module AuthenticationHelper
  def unlink_from_facebook_link
    link_to "Unlink from Facebook", confirm_facebook_unlinking_path, :class => 'connectacct-link facebook-auth disconnect-fb', :id => 'facebook-connect'
  end

  def link_with_facebook_link
    link_to("Connect with Facebook", person_omniauth_authorize_path(:facebook), :class => 'connectacct-link facebook-auth', :id => 'facebook-connect' )
  end

  def facebook_sign_in_link
    link_to "Sign in with Facebook", person_omniauth_authorize_path(:facebook), :class => 'createacct-link facebook-auth fb-login-btn'
  end

  # uses url instead of path if https
  def person_omniauth_authorize_path_or_url(provider)
    SecureUrlHelper.https? ? person_omniauth_authorize_url(provider, :protocol => 'https') : person_omniauth_authorize_path(provider)
  end

  def person_omniauth_authorize_url(provider, params = {})
    if Devise.omniauth_configs[provider.to_sym]
      "#{root_url(:protocol => params.delete(:protocol))}people/auth/#{provider}#{'?'+params.to_param if params.present?}"
    else
      raise ArgumentError, "Could not find omniauth provider #{provider.inspect}"
    end
  end
end
