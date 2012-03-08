class ReflectionsController < ApplicationController
  layout 'opportunity'

  # GET /reflections
  # GET /reflections.xml
  def index
    @conversation = Conversation.find(params[:conversation_id])
    @reflections = Reflection.all

    respond_to do |format|
      format.html # index.html.erb
      format.xml  { render :xml => @reflections }
    end
  end

  # GET /reflections/1
  # GET /reflections/1.xml
  def show
    @conversation = Conversation.find(params[:conversation_id])
    @reflection = Reflection.find(params[:id])

    respond_to do |format|
      format.html # show.html.erb
      format.xml  { render :xml => @reflection }
    end
  end

  # GET /reflections/new
  # GET /reflections/new.xml
  def new
    @conversation = Conversation.find(params[:conversation_id])
    @reflection = Reflection.new

    respond_to do |format|
      format.html # new.html.erb
      format.xml  { render :xml => @reflection }
    end
  end

  # GET /reflections/1/edit
  def edit
    @conversation = Conversation.find(params[:conversation_id])
    @reflection = Reflection.find(params[:id])
  end

  # POST /reflections
  # POST /reflections.xml
  def create
    @conversation = Conversation.find(params[:conversation_id])
    @reflection = Reflection.new(params[:reflection])

    respond_to do |format|
      if @reflection.save
        format.html { redirect_to conversation_reflection_path @conversation, @reflection, :notice => 'Reflection was successfully created.' }
        format.xml  { render :xml => @reflection, :status => :created, :location => @reflection }
      else
        format.html { render :controller => [@conversation, @reflection], :action => "new" }
        format.xml  { render :xml => @reflection.errors, :status => :unprocessable_entity }
      end
    end
  end

  # PUT /reflections/1
  # PUT /reflections/1.xml
  def update
    @conversation = Conversation.find(params[:conversation_id])
    @reflection = Reflection.find(params[:id])

    respond_to do |format|
      if @reflection.update_attributes(params[:reflection])
        format.html { redirect_to(@reflection, :notice => 'Reflection was successfully updated.') }
        format.xml  { head :ok }
      else
        format.html { render :action => "edit" }
        format.xml  { render :xml => @reflection.errors, :status => :unprocessable_entity }
      end
    end
  end

  # DELETE /reflections/1
  # DELETE /reflections/1.xml
  def destroy
    @conversation = Conversation.find(params[:conversation_id])
    @reflection = Reflection.find(params[:id])
    @reflection.destroy

    respond_to do |format|
      format.html { redirect_to(reflections_url) }
      format.xml  { head :ok }
    end
  end
end
