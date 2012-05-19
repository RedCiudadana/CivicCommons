class IssuesTopic < ActiveRecord::Base
  belongs_to :issue
  belongs_to :topic
end