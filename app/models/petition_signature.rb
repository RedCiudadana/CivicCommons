class PetitionSignature < ActiveRecord::Base
  belongs_to :petition
  belongs_to :person
  validates_presence_of :petition_id, :person_id

  delegate :conversation, :title, :description, :to => :petition, :prefix => true
  def petition_name
    petition.title
  end
  def signer_name
    person.name
  end
  def conversation_id
    try(:petition).try(:conversation_id)
  end
end
