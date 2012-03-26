require 'spec_helper'

describe PetitionsController do

  def stub_conversation(stubs={})
    @stub_conversation ||= stub_model(Conversation, stubs).as_null_object
  end

  def stub_petition(stubs={})
    @stub_petition ||= stub_model(Petition, stubs).as_null_object
  end

  def stub_person(stubs={:id => 111})
    @stub_person ||= stub_model(Person, stubs).as_null_object
  end

  before(:each) do
    @controller.stub!(:require_user).and_return(true)
    @controller.stub!(:current_person).and_return(stub_person)
    Conversation.stub!(:find).and_return(stub_conversation)
  end

  describe "new" do
    it "should find the conversation" do
      Conversation.should_receive(:find).with(123).and_return(stub_conversation)
      get :new, :conversation_id => 123
    end
    it "should build a petition" do
      petitions_double = double
      @stub_conversation.should_receive(:petitions).and_return(petitions_double)
      petitions_double.should_receive(:build).and_return(stub_petition)
      get :new, :conversation_id => 123
    end
  end

  describe "show" do
    it "should show the petition" do
      petitions_double = double
      @stub_conversation.should_receive(:petitions).and_return(petitions_double)
      petitions_double.should_receive(:find).with(1234).and_return(stub_petition)

      get :show, :conversation_id => 123, :id => 1234
    end
  end


  describe "create" do
    before(:each) do
      @petitions_double = double
      @stub_conversation.stub!(:petitions).and_return(@petitions_double)
      @petitions_double.stub!(:build).and_return(stub_petition)
    end
    it "should build the petition" do
      @stub_conversation.should_receive(:petitions).and_return(@petitions_double)
      @petitions_double.should_receive(:build).and_return(stub_petition)
      post :create, :conversation_id => 123
    end
    it "should set the person_id on the petition" do
      stub_petition.should_receive(:person_id=).with(stub_person.id)
      post :create, :conversation_id => 123
    end
    it "should save it the petition" do
      stub_petition.should_receive(:save)
      post :create, :conversation_id => 123
    end
    it "should redirect to the petition if can be saved" do
      stub_petition.stub!(:save).and_return(true)
      post :create, :conversation_id => 123
      response.should redirect_to conversation_petition_path(@stub_conversation.id, stub_petition.id)
    end
    it "should render the action :new if cannot be saved" do
      stub_petition.stub!(:save).and_return(false)
      response.should_not redirect_to conversation_petition_path(@stub_conversation.id, stub_petition.id)
      response.should render_template :action => :new
    end
  end

  describe "sign" do
    before(:each) do
      @petitions_double = double
      @stub_conversation.should_receive(:petitions).and_return(@petitions_double)
      @petitions_double.stub!(:find).with(1234).and_return(stub_petition)
    end

    it "should find the petition" do
      @petitions_double.should_receive(:find).with(1234).and_return(stub_petition)
      post :sign, :conversation_id => 123, :id => 1234
    end

    it "should set the current user to sign the petition" do
      stub_petition.should_receive(:sign).with(stub_person)
      post :sign, :conversation_id => 123, :id => 1234
    end

    it "should return the flash message" do
      post :sign, :conversation_id => 123, :id => 1234
      flash[:petition_notice].should == "<strong>Thank you!</strong> You successfully signed this petition."
    end

  end

  describe "sign_modal" do
    before(:each) do
      petitions_double = double
      @stub_conversation.should_receive(:petitions).and_return(petitions_double)
      petitions_double.should_receive(:find).with(1234).and_return(stub_petition)
    end

    it "should return the sign_modal template" do
      get :sign_modal, :conversation_id => 123, :id => 1234
      response.should render_template 'sign_modal'
    end
  end


end
