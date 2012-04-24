class Organization < Person
  include Subscribable
  attr_accessor :authorized_to_setup_an_account

  validates_presence_of :name

  has_many :organization_members, uniq: true
  has_many :members,
    class_name: 'Person',
    source: :person,
    through: :organization_members,
    uniq: true

  validates_acceptance_of :authorized_to_setup_an_account, :on => :create, :message => 'must be checked.'

  alias_attribute :name, :last_name

  define_method(:title) do
    name
  end

  def allow_facebook_connect?
    false
  end

  def has_member?(person)
    !person.blank? && self.members.exists?(person)
  end

  def join_as_member(person)
    self.members << person
  end

  def remove_member(person)
    self.members.delete(person)
  end
end
