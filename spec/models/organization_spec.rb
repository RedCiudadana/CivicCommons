require 'spec_helper'

describe Organization do

  subject { FactoryGirl.create(:organization, name: 'The Civic Commons') }

  let(:user) {FactoryGirl.create(:normal_person)}
  let(:allowed_image_types) {["image/gif", "image/jpeg", "image/png", "image/bmp"]}

  it { should be_valid }
  it { subject.organization_detail.should_not be_blank }
  it { should have_attached_file :avatar }
  it { should validate_attachment_content_type(:avatar).allowing(allowed_image_types).rejecting(['text/plain']) }

  context "validation" do
    it "should validate on name" do
      org = FactoryGirl.build(:organization, :name=>'')
      org.valid?
      org.errors[:name].should == ["can't be blank"]
    end

    it "should not validate first_name and last_name" do
      org = FactoryGirl.build(:organization, :first_name=>'', :last_name => '')
      org.valid?
      org.errors[:first_name].should be_blank
      org.errors[:last_name].should be_blank
    end
  end

  context "Inheritance" do
    it "should be a subclass of Person" do
      Organization.superclass.should == Person
    end
  end
  context "Associations" do
    it "should have organization details" do
      Organization.reflect_on_association(:organization_detail).macro == :has_one
    end
    it "should have many people" do
      Organization.reflect_on_association(:members).macro.should == :has_many
    end
    it "should be have uniqueness constraint on habtm members" do
      Organization.reflect_on_association(:members).options[:uniq].should be_true
    end
  end

  context "defaults" do
    it "should have allow_facebook_connect? to be false always" do
      Organization.new.allow_facebook_connect?.should be_false
    end
  end

  context "organization members" do
    before(:each) do
      @organization = FactoryGirl.create(:organization)
      @person = FactoryGirl.create(:person)
    end

    context "has_member?" do
      it "should have the proper member" do
        @organization.has_member?(@person).should_not be_true
        @organization.join_as_member(@person)

        @organization.reload
        @organization.has_member?(@person).should be_true
      end
      it "should return false when nil is passed in" do
        @organization.has_member?(nil).should be_false
      end
    end
    context "join_as_members" do
      it "should add a person as a member" do
        @organization.join_as_member(@person)
        @organization.reload
        @organization.members.should == [@person]
      end
      it "should not allow to add the same person as a member" do
        @organization.join_as_member(@person)
        @organization.join_as_member(@person)
        @organization.members.should == [@person]
      end
    end
    context "remove_member" do
      it "should remove a person from membership of an arganization" do
        @organization.join_as_member(@person)
        @organization.reload
        @organization.members.should == [@person]
        @organization.remove_member(@person)
        @organization.members.should be_blank
      end
    end
  end

  context "subscription" do
    it 'is created by calling subscribe' do
      subscription = subject.subscribe(user)
      subscription.subscribable.name.should == 'The Civic Commons'
    end
  end
end
