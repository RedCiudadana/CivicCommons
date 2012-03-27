require 'spec_helper'

describe Article do
  describe "Validation" do
    it "is valid" do
      @article = Factory.build(:article)
      @article.should be_valid
    end
  end

  context "paperclip" do
    it "will have necessary db columns for paperclip" do
      should have_db_column(:image_file_name).of_type(:string)
      should have_db_column(:image_content_type).of_type(:string)
      should have_db_column(:image_file_size).of_type(:integer)
    end
    it "should not have validation for content type", :pending => 'broke during rails3 upgrade' do
      should_not validate_attachment_content_type(:image)
    end
    it "should not have default image" do
      Article.attachment_definitions[:image][:default_url].should be_nil
    end
  end

end
