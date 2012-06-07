class Petition < ActiveRecord::Base
  belongs_to :conversation
  belongs_to :person
  has_one :action, :as => :actionable, :dependent => :destroy
  has_many :signatures, :class_name => 'PetitionSignature', :dependent => :destroy

  has_many :signers, :class_name => 'Person', :through => :signatures, :source => :person

  validates_presence_of :title,
                        :description,
                        :resulting_actions,
                        :signature_needed,
                        :person_id
  validates_numericality_of :signature_needed, :greater_than => 0, :allow_blank => true

  alias_attribute :participants, :signers

  after_save :create_or_update_action

  def creator_name
    self.person.name
  end

  def reflections
    self.action.reflections
  end

  def signed_by?(person)
    signers.exists?(person)
  end

  def signature_needed_left
    if signature_needed > signatures.count
      signature_needed - signatures.count
    else
      0
    end
  end

  def sign(person)
    unless signers.exists?(person)
      self.signers << person
    end
  end

  # Needed to create the Action model when Petition is created
  def create_or_update_action
    if self.action.present?
      self.action.update_attributes(:conversation_id => self.conversation_id) if self.conversation_id_changed?
    else
      self.build_action(:conversation_id => self.conversation_id).save if self.conversation_id.present?
    end
  end

end

