require 'spec_helper'

describe SurveyOption do
  context "attributes" do
    before(:each) do
      @survey_option = SurveyOption.new
    end
    it "should have :winner" do
      @survey_option.respond_to?(:winner).should be_true
    end
    it "should have :voted" do
      @survey_option.respond_to?(:voted).should be_true
    end
    it "should have :weighted_votes_percentage" do
      @survey_option.respond_to?(:weighted_votes_percentage).should be_true
    end
  end
  context "Associations" do
    it "should belong to poll" do
      SurveyOption.reflect_on_association(:survey).macro.should == :belongs_to
    end
    
    it "should have many selected_survey_options" do
      SurveyOption.reflect_on_association(:selected_survey_options).macro.should == :has_many
    end
    
    it "should destroy the selected_survey_options" do
      SurveyOption.reflect_on_association(:selected_survey_options).options[:dependent].should == :destroy
    end
  end

  context "Validations" do
    def given_an_invalid_survey_option
      @survey_option = SurveyOption.create
    end
    
    it "should validate presence of survey" do
      given_an_invalid_survey_option
      @survey_option.errors[:survey_id].should == ["can't be blank"]
    end
    
    it "should validate uniqueness of survey" do
      @survey_option1 = FactoryGirl.create(:survey_option, :position => 1, :survey_id => 1)
      @survey_option2 = FactoryGirl.build(:survey_option, :position => 1, :survey_id => 1)
      @survey_option2.valid?
      @survey_option2.errors[:position].should == ["has already been taken"]
    end
    
    context "validating on validate_title_or_description" do
      it "should return an error if title is blank and description is blank" do
        @survey_option = FactoryGirl.build(:survey_option, :position => 1, :survey_id => 1, :title => nil,:description => nil)
        @survey_option.valid?
        @survey_option.errors[:title].include?('Either title must be filled, or description must be filled').should be_true
      end
      it "should not return an error if title is not blank and description is blank" do
        @survey_option = FactoryGirl.build(:survey_option, :position => 1, :survey_id => 1, :title => 'hello title', :description => nil)
        @survey_option.valid?
        @survey_option.errors[:title].should be_blank
      end
      it "should not return an error if title is blank and description is not blank" do
        @survey_option = FactoryGirl.build(:survey_option, :position => 1, :survey_id => 1, :title => nil, :description => 'hello description')
        @survey_option.valid?
        @survey_option.errors[:title].should be_blank
      end
      
      
    end
  end
  
  context "named scope" do
    def given_a_few_surveys 
      @survey_option2 = FactoryGirl.create(:survey_option, :position => 2)
      @survey_option1 = FactoryGirl.create(:survey_option, :position => 1)
    end

    it "should " do
      given_a_few_surveys
      SurveyOption.position_sorted.all.should == [@survey_option1, @survey_option2]
    end
    
  end

end
