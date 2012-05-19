require 'spec_helper'

module Admin
  describe ContentItemsController do

    before(:each) do
      EmbedlyService.stub!(:get_simple_embed).and_return(nil)
    end

    before(:each) do
      sign_in FactoryGirl.create(:admin_person)
    end

    describe "GET index" do

      before(:each) do
        @content_items = {}
        (1..5).each do
          content_item = FactoryGirl.create(:content_item)
          @content_items[content_item.id] = content_item
        end
      end

      it "assigns all content_items as @content_items" do
        get :index
        assigns[:content_items].size.should == @content_items.size
      end

    end

    describe "GET show" do

      let(:content_item) do
        FactoryGirl.create(:content_item)
      end

      it "assigns the requested content_item as @content_item" do
        get :show, :id => content_item.id.to_s
        assigns[:content_item].should eq content_item
      end

    end

    describe "GET new" do

      it "assigns a new content_item as @content_item" do
        get :new
        assigns[:content_item].should_not be_nil
      end

    end

    describe "GET edit" do

      let(:content_item) do
        FactoryGirl.create(:content_item)
      end

      it "assigns the requested content_item as @content_item" do
        get :edit, :id => content_item.id.to_s
        assigns[:content_item].should eq content_item
      end

    end

    describe "POST create" do
      let(:params) do
        topic = FactoryGirl.create(:topic)
        attributes = FactoryGirl.attributes_for(:content_item)
        #attributes = FactoryGirl.create(:content_item).attributes
        attributes.delete(:topics)
        attributes[:topic_ids]=[topic.id]
        attributes
      end

      describe "with valid params" do

        let(:author) do
          FactoryGirl.create(:admin_person)
        end


        before(:each) do
          params[:author] = author
          params.delete(:published)

          post :create, :content_item => params
        end

        it "assigns a newly created content_item as @content_item" do
          assigns[:content_item].title.should eq params[:title]
          assigns[:content_item].summary.should eq params[:summary]
        end

        it "redirects to the created content_item" do
          response.should redirect_to admin_content_item_path(assigns[:content_item].slug)
        end

      end

      describe "with invalid params" do

        let(:author) do
          FactoryGirl.create(:admin_person)
        end

        before(:each) do
          params[:author] = author
          params.delete(:title)
          post :create, :content_item => params
        end

        it "assigns a newly created but unsaved content_item as @content_item" do
          assigns[:content_item].summary.should eq params[:summary]
        end

        it "re-renders the 'new' content_item" do
          response.should render_template('new')
        end

      end

      describe "with valid Embedly integration" do

        let(:author) do
          FactoryGirl.create(:admin_person)
        end

        before(:each) do
          params[:author] = author
          params.delete(:published)
        end

        it "does not call Embedly when no external link is given" do
          params.delete(:external_link)
          params[:embed_code] = "Some Embed Code"
          EmbedlyService.should_not_receive(:get_simple_embed)
          post :create, :content_item => params
          assigns[:content_item].embed_code.should eq params[:embed_code]
        end

        it "gets Embedly embed code when given an external link and no embed code" do
          params[:external_link] = "http://www.theciviccommons.com"
          params.delete(:embed_code)
          EmbedlyService.should_receive(:get_simple_embed).once.and_return("embed")
          post :create, :content_item => params
          assigns[:content_item].external_link.should eq params[:external_link]
          assigns[:content_item].embed_code.should eq "embed"
        end

        it "does not get Embedly embed code when given an external link and an embed code" do
          params[:external_link] = "http://www.theciviccommons.com"
          params[:embed_code] = "Some Embed Code"
          EmbedlyService.should_not_receive(:get_simple_embed)
          post :create, :content_item => params
          assigns[:content_item].external_link.should eq params[:external_link]
          assigns[:content_item].embed_code.should eq params[:embed_code]
        end

      end

    end

    describe "PUT update" do

      let(:content_item) do
        FactoryGirl.create(:content_item)
      end

      let(:new_title) do
        "Some completely different but valid title"
      end

      let(:params) do
        content_item.attributes
      end

      describe "with valid params" do

        before(:each) do
          params.delete('published')
          params['title'] = new_title
          put :update, :id => params['id'], :content_item => params
        end

        it "updates the requested content_item" do
          ContentItem.find_by_id(params['id']).title.should eq new_title
        end

        it "assigns the requested content_item as @content_item" do
          assigns[:content_item].id.should eq params['id']
          assigns[:content_item].title.should eq new_title
          assigns[:content_item].summary.should eq params['summary']
        end

        it "redirects to the 'GET show' page" do
          response.should redirect_to admin_content_item_path(content_item)
        end

      end

      describe "with invalid params" do

        before(:each) do
          params.delete('published')
          params['title'] = ''
          put :update, :id => params['id'], :content_item => params
        end

        it "assigns the content_item as @content_item" do
          assigns[:content_item].id.should eq params['id']
          assigns[:content_item].title.should eq params['title']
          assigns[:content_item].summary.should eq params['summary']
          assigns[:content_item].slug.should eq params['slug']
        end

        it "re-renders the 'edit' content_item" do
          response.should render_template('edit')
        end

      end

    end

    describe "DELETE destroy" do

      let(:content_item) do
        FactoryGirl.create(:content_item)
      end

      before(:each) do
        delete :destroy, :id => content_item.id
      end

      it "destroys the requested content_item" do
        ContentItem.find_by_id(content_item.id).should be_nil
      end

      it "redirects to the content_items list" do
        response.should redirect_to(admin_content_items_path)
      end

    end

  end
end
