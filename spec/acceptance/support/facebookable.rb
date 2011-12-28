module Facebookable
  FACEBOOK_AUTH_HASH = {
    'credentials' => {'token'=>"1234567890"}, 
    'provider' => "facebook",
    'uid' => "12345",
    'user_info' => { 'first_name' => 'John', 'last_name' => 'doe', 'name' => 'John Doe'},
    'extra' => { 'user_hash' => { 'email' => "johnd@test.com" } } 
  }
  def stub_facebook_auth
    enact_stub FACEBOOK_AUTH_HASH
  end

  def stub_facebook_auth_with_email_for user
    enact_stub FACEBOOK_AUTH_HASH.merge({ 'extra' => { 'user_hash' => { 'email' => user.email } } })
  end
  def enact_stub hash
    OmniAuth.config.add_mock(:facebook, hash)
  end
  def stub_facebook_auth_for user
    enact_stub({
      credentials: { token: user.facebook_authentication.token },
      provider: :facebook,
      uid: user.facebook_authentication.uid,
      user_info: { first_name: user.first_name, last_name: user.last_name, name: user.name },
      extra: { user_hash: { email: user.email }}
    })
  end
  
end