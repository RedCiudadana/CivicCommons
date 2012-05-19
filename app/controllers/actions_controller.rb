class ActionsController < ApplicationController
  layout 'opportunity'
  
  before_filter :find_conversation
  
  def index
    @actions = @conversation.actions.order('id DESC')
    @participants = @conversation.action_participants
  end

protected

  def find_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end
  
end