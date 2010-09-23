require 'parent_validator'

class Contribution < ActiveRecord::Base
  include Rateable
  include Visitable
  include TopItemable
  acts_as_nested_set
  
  belongs_to :person, :foreign_key => "owner"
  belongs_to :conversation
  belongs_to :issue
  
  validates_with ContributionValidator
  validates :person, :presence=>true 
  validates_associated :conversation, :parent, :person
  
  # paperclip bug: if you don't specify the path, you will get
  # a stack overflow when trying to upload an image.
  # return an open File object that contains our Amazon S3 credentials.
  filename = '/data/TheCivicCommons/shared/config/amazon_s3.yml' # the way it lands on EngineYard
  filename = Rails.root + 'config/amazon_s3.yml' unless File.exist? filename
  s3_credential_file = File.new(filename)

  has_attached_file :attachment,
    :storage => :s3,
    :s3_credentials => s3_credential_file,
    :path => ":attachment/:id/:filename"
      
end