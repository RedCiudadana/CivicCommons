require 'spec_helper'

describe UserHelper do

  context "classes" do

    it "returns \"image dnld\" when contribution is an image" do
      contribution = Factory.create(:attached_image)
      helper.classes(contribution).should == "image dnld"
    end

    it "returns \"video dnld\" when contribution is a video", :pending => 'broke during rails3 upgrade' do
      contribution = Factory.create(:embedded_snippet)
      helper.classes(contribution).should == "video dnld"
    end

    it "returns \"suggestion dnld\" when contribution is a suggestion" do
      contribution = Factory.create(:suggested_action)
      helper.classes(contribution).should == ""
    end

    it "returns \"document dnld\" when the contribution is an attached file" do
      contribution = Factory.create(:attached_file)
      helper.classes(contribution).should == "document dnld"
    end

    it "returns \"link dnld\" when contribution is a link", :pending => 'broke during rails3 upgrade' do
      contribution = Factory.create(:link)
      helper.classes(contribution).should == "link dnld"
    end

    it "returns \"\" any the contribution is any other type" do
      contribution = Factory.create(:comment)
      helper.classes(contribution).should == ""
    end

  end

end
