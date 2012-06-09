require 'spec_helper'

describe Petition do
  describe "factories" do
    it "should be valid" do
      FactoryGirl.build(:petition).should be_valid
      FactoryGirl.create(:petition).should be_valid
      FactoryGirl.build(:unsigned_petition).should be_valid
      FactoryGirl.create(:unsigned_petition).should be_valid
    end
  end

  describe "validation" do
    it "should validate presence of title" do
      should validate_presence_of(:title)
    end

    it "should validate presence of description" do
      should validate_presence_of(:description)
    end

    it "should validate presence of resulting_actions" do
      should validate_presence_of(:resulting_actions)
    end

    it "should validate presence of person_id" do
      should validate_presence_of(:person_id)
    end

    it "should validate presence of signature_needed" do
      should validate_presence_of(:signature_needed)
    end

    it "should validate numericality of signature_needed to be greater than 0" do
      should validate_numericality_of(:signature_needed)
    end
  end
  describe "Associations" do
    it "should belong_to conversation" do
      should belong_to(:conversation)
    end
    it "should have many signatures" do
      should have_many(:signatures).dependent(:destroy)
    end
    it "should have many signers" do
      should have_many(:signers).through(:signatures)
    end
    it "should has one action as actionable" do
      should have_one(:action)
    end
  end
  describe "reflections" do
    it "should have many reflections" do
      @petition = FactoryGirl.create(:petition)
      @reflection = FactoryGirl.create(:reflection,:actions => [@petition.action])
      @petition.reflections.should == [@reflection]
    end
  end
  describe "signed_by?" do
    def given_petition_signed_by_person
      @petition = FactoryGirl.create(:petition)
      @person = @petition.signers.first
    end
    it "should correctly confirm if a petition is signed by someone" do
      given_petition_signed_by_person
      @petition.signed_by?(@person).should be_true
    end
    it "should not confirm if petition is not signed by person" do
      given_petition_signed_by_person
      @person2 = FactoryGirl.create(:person)
      @petition.signed_by?(@person2).should be_false
    end
  end
  describe "sign" do
    def given_un_signed_petition
      @petition = FactoryGirl.create(:unsigned_petition)
      @person = FactoryGirl.create(:person)
    end
    it "should sign the person" do
      given_un_signed_petition
      @petition.signers.should == []
      @petition.sign(@person)
      @petition.signers.include?(@person).should be_true
    end
  end

  describe 'signature_needed_left' do
    it "should return 0 if number of signatures are more than needed" do
      stubber = double
      @petition = FactoryGirl.build(:petition, :signature_needed => 10)
      @petition.stub!(:signatures).and_return(stubber)
      stubber.stub!(:count).and_return(1)

      @petition.signature_needed_left.should == 9
    end
    it "should return the real number if the number of signatures are less than needed" do
      stubber = double
      @petition = FactoryGirl.build(:petition, :signature_needed => 10)
      @petition.stub!(:signatures).and_return(stubber)
      stubber.stub!(:count).and_return(20)

      @petition.signature_needed_left.should == 0
    end
  end
  describe "after_create" do
    describe "after_update" do
      it "should modify the action model if Petition is updated" do
        @petition = FactoryGirl.create(:petition, :conversation_id => 123)
        @action = Action.first
        @action.conversation_id.should == 123
        @petition.conversation_id = 111
        @petition.save
        @action.reload.conversation_id.should == 111
      end
    end
    describe "create_action" do
      it "should create the action model once a petition is created" do
        FactoryGirl.create(:petition)
        Action.first.should == Petition.first.action
      end
    end
  end

  context "delegation" do
    before(:each) do
      @petition = FactoryGirl.build(:petition)
    end
    it "creator_name to a petitions creators name" do
      @petition.creator_name.should == @petition.person.name
    end
  end
end
