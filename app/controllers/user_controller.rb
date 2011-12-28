class UserController < ApplicationController

  before_filter :require_ssl, :only => [:update]
  before_filter :verify_ownership?, :only => [:edit, :update, :destroy_avatar]

  def verify_ownership?
    unless(current_person && current_person == Person.find(params[:id]))
      redirect_to community_path
    end
  end

  def edit
    @person = Person.find(params[:id])
    @person.require_zip_code = true  #did this So that there is a validation error on the view.
    @person.valid?
  end

  def show
    unless Person.exists? cached_slug: params[:id]
      redirect_to community_path
      return
    end
    user = Person.includes(:contributions, :subscriptions, :organization_detail).find(params[:id])
    @user = ProfilePresenter.new(user, page: params[:page])
    @organization_subscriptions = @user.subscriptions_organizations.reverse
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def update
    @person = Person.find(params[:id])
    @person.require_zip_code = true
    respond_to do |format|
      if @person.update_attributes(params[:person])
        flash[:notice] = "Successfully edited your profile"
        format.html { redirect_to user_url(@person) }
      else
        format.html { render :action => "edit" }
      end
    end
  end

  def destroy_avatar
    @person = Person.find(params[:id])
    @person.avatar = nil
    if @person.save
      respond_to do |format|
        format.js { render :json => { :avatarUrl => ( @person.facebook_authenticated? && !@person.avatar? ? @person.facebook_profile_pic_url : @person.avatar.url )} }
      end
    else
      respond_to do |format|
        format.js { render :nothing => true, :status => 500 }
      end
    end
  end

end
