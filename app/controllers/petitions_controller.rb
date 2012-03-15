class PetitionsController < ApplicationController
  layout 'opportunity'

  before_filter :require_user, :except => [:show]
  before_filter :find_conversation

  def new
    @petition = @conversation.petitions.build
  end

  def show
    @petition = @conversation.petitions.find(params[:id])
  end

  def create
    @petition = @conversation.petitions.build(params[:petition])
    @petition.person_id = current_person.id
    if @petition.save
      redirect_to conversation_petition_path(@conversation, @petition)
    else
      render :action => :new
    end
  end

  def sign
    @petition = @conversation.petitions.find(params[:id])
    @petition.sign(current_person)
    flash[:petition_notice] = '<strong>Thank you!</strong> You successfully signed this petition.'
    redirect_to conversation_petition_path(@conversation, @petition)
  end

  def sign_modal
    @petition = @conversation.petitions.find(params[:id])
    #returns the sign modal dialog
    render :layout => false
  end

protected
  def find_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end
end
