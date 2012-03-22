require 'spec_helper'
include ControllerMacros

describe Admin::SurveysController do
  before(:each) do
    login_admin
    @survey = Factory.create(:survey)
  end

  describe "GET index" do
    it "assigns all surveys as @surveys" do
      get :index
      assigns(:surveys).first.id.should eq(@survey.id)
    end
  end

  describe "GET show" do
    it "assigns the requested survey as @survey" do
      get :show, :id => @survey.id
      assigns(:survey).id.should be(@survey.id)
    end
  end

  describe "GET new" do
    it "assigns a new survey as @survey" do
      get :new
      assigns(:survey).new_record?.should be_true
    end

    it "should defult to Vote, as a Survey STI" do
      get :new
      assigns(:survey).type.should == 'Vote'
    end
  end

  describe "GET edit" do
    it "assigns the requested survey as @survey" do
      get :edit, :id => @survey.id
      assigns(:survey).id.should == @survey.id
    end
  end

  describe "POST create" do
    describe "with valid params" do
      it "assigns a newly created survey as @survey" do
        survey = Factory.build(:survey, title: 'Survey Title')
        post :create, :survey => survey.attributes
        assigns(:survey).title.should be(survey.title)
      end

      it "should create an STI model based on type" do
        survey = Factory.build(:survey)
        post :create, :survey => survey.attributes
        assigns(:survey).type.should == 'Vote'
      end

      it "redirects to the created survey" do
        survey = Factory.build(:survey)
        post :create, :survey => survey.attributes
        response.should redirect_to(admin_survey_path(assigns(:survey).id))
      end
    end

    describe "with invalid params" do
      it "assigns a newly created but unsaved survey as @survey" do
        survey = Factory.build(:survey, title: '')
        post :create, :survey => survey.attributes
        assigns(:survey).title.should == survey.title
      end

      it "re-renders the 'new' template" do
        post :create, :survey => {}
        response.should render_template("new")
      end
    end
  end

  describe "PUT update" do
    describe "with valid params" do
      it "updates the requested survey" do
        attributes = @survey.attributes
        attributes['title'] = 'blah blah'
        put :update, :id => @survey.id, :survey => attributes
        Survey.find(@survey.id).attributes == attributes
      end

      it "assigns the requested survey as @survey" do
        put :update, :id => @survey.id
        assigns(:survey).id.should be(@survey.id)
      end

      it "redirects to the survey" do
        put :update, :id => @survey.id
        response.should redirect_to(admin_survey_path(@survey))
      end
    end

    describe "with invalid params" do
      it "assigns the survey as @survey" do
        put :update, :id => @survey.id, :survey => { title: '' }
        assigns(:survey).id.should be(@survey.id)
      end

      it "re-renders the 'edit' template" do
        put :update, :id => @survey.id, :survey => { title: '' }
        response.should render_template("edit")
      end
    end
  end

  describe "DELETE destroy" do
    it "destroys the requested survey" do
      delete :destroy, :id => @survey.id
      Survey.where(id: @survey.id).length.should == 0
    end

    it "redirects to the admin_surveys list" do
      delete :destroy, :id => @survey.id
      response.should redirect_to(admin_surveys_path)
    end
  end

  describe "GET progress" do
    it "assigns the requested survey as @survey" do
      get :progress, :id => @survey.id
      assigns(:survey).id.should be(@survey.id)
    end

    it "gets the survey responses based on last voted" do
      survey = Factory.create(:survey_with_options)
      survey_response = Factory.create(:survey_response, survey: survey, person: @user)
      get :progress, :id => survey.id
      assigns(:responses).should == [survey_response]
    end
  end

end
