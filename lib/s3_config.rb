require 'config/configurator'
module S3Config
  include Configurator
  extend self
  
  def credential_file
    # paperclip bug: if you don't specify the path, you will get
    # a stack overflow when trying to upload an image.
    # return an open File object that contains our Amazon S3 credentials.
    filename = '/data/TheCivicCommons/shared/config/amazon_s3.yml' # the way it lands on EngineYard
    unless File.exist?(filename)
      filename = Rails.root + 'config/amazon_s3.yml'
    end
    File.new(filename)
  end

  load_config(:file => credential_file, :environment => Rails.env)
  
end
