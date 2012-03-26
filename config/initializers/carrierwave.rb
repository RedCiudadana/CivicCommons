CarrierWave.configure do |config|
  config.fog_credentials = {
    :provider               => 'AWS',       # required
    :aws_access_key_id      => S3Config.access_key_id,   # required
    :aws_secret_access_key  => S3Config.secret_access_key  # required
    #:region                 => 'eu-west-1'  # optional, defaults to 'us-east-1'
  }
  config.fog_directory  = S3Config.bucket                          # required
  config.fog_host       = "http://s3.amazonaws.com/#{S3Config.bucket}"# 'https://assets.example.com'  # optional, defaults to nil
  #config.fog_public     = false                                   # optional, defaults to true
  #config.fog_attributes = {'Cache-Control'=>'max-age=315576000'}  # optional, defaults to {}
end