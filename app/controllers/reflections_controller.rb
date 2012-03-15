class ReflectionsController < ApplicationController
  layout 'opportunity'

  before_filter :require_user, :except => [:index, :show]
  before_filter :find_conversation

  def index
    @reflections = Reflection.where(:conversation_id => @conversation).all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @reflections }
    end
  end

  def show
    @reflection = Reflection.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @reflection }
    end
  end

  def new
    @reflection = Reflection.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @reflection }
    end
  end

  def edit
    @reflection = Reflection.find(params[:id])
  end

  def create
    @reflection = Reflection.new(params[:reflection])
    @reflection.owner = current_person.id if @reflection.owner.blank? && current_person

    respond_to do |format|
      if @reflection.save
        format.html { redirect_to conversation_reflection_path @conversation, @reflection }
        format.xml  { render :xml => @reflection, :status => :created, :location => @reflection }
      else
        format.html { render :controller => [@conversation, @reflection], :action => "new" }
        format.xml  { render :xml => @reflection.errors, :status => :unprocessable_entity }
      end
    end
  end

  def update
    @reflection = Reflection.find(params[:id])

    respond_to do |format|
      if @reflection.update_attributes(params[:reflection])
        format.html { redirect_to([@conversation, @reflection], :notice => 'Reflection was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @reflection.errors, :status => :unprocessable_entity }
      end
    end
  end

  def destroy
    @reflection = Reflection.find(params[:id])
    @reflection.destroy

    respond_to do |format|
      format.html { redirect_to(conversation_reflections_url @conversation) }
      format.xml  { head :ok }
    end
  end

  protected
  def find_conversation
    @conversation = Conversation.find(params[:conversation_id])
  end
end
