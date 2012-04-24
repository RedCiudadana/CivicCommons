require 'spec_helper'

describe Regionable do
  before(:each) do
    @issue = FactoryGirl.create(:issue, :zip_code => '11111')
    @region = FactoryGirl.create(:region)
    FactoryGirl.create(:zip_code, :region => @region, :zip_code => '11111')
  end

  context "when a region exists for its zipcode" do
    it "finds the correct region from its zipcode" do
      @issue.region.should == @region
    end
  end

  context "when no region exists for its zipcode" do
    it "returns a default region" do
      @issue = FactoryGirl.create(:issue, :zip_code => '22222')
      @issue.region.attributes.should == Region.default.attributes
    end

  end

  describe "class methods" do
    before(:each) do
      @issue = FactoryGirl.create(:issue, :zip_code => '12345')
      @region = FactoryGirl.create(:region)
      FactoryGirl.create(:zip_code, :region => @region, :zip_code => '12345')
      FactoryGirl.create(:zip_code, :region => @region, :zip_code => '333333')
    end

    it "adds a class method to region that finds all of its type" do
      @region.reload.zip_codes.length.should == 2
      @region.issues.first.id.should == @issue.id
    end

  end
end
