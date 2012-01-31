class UserController < ApplicationController
  include OrganizationsHelper
  before_filter :require_user, :only => [:join_as_member, :remove_membership]
  before_filter :require_ssl, :only => [:update,:edit]
  skip_before_filter :require_no_ssl, :only => [:update, :edit, :destroy_avatar]
  before_filter :verify_ownership?, :only => [:edit, :update, :destroy_avatar]

  def verify_ownership?
    unless(current_person && current_person == Person.find(params[:id]))
      redirect_to community_path
    end
  end

  def join_as_member
    @organization = Organization.find(params[:id])
    if @organization && @organization.join_as_member(current_person) 
      respond_to do |format|
        format.js { render :template => '/organizations/join_as_member.js'  } 
      end
    else
      respond_to do |format|
        format.js { render :nothing => true, :status => 500 }
      end
    end
  end

  def remove_membership
    @organization = Organization.find(params[:id])
    if @organization && @organization.remove_member(current_person)
      respond_to do |format|
        format.js { render :template => '/organizations/remove_membership.js' }
      end
    else
      respond_to do |format|
        format.js { render :nothing => true, :status => 500 }
      end
    end
  end

  def confirm_membership
    render :template => '/organizations/confirm_membership_modal', :layout => false
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
    respond_to do |format|
      format.html
      format.xml
    end
  end

  def update
    @person = Person.find(params[:id])
    @person.require_zip_code = true
    attributes = params[:person] || params[:organization]
    respond_to do |format|
      if @person.update_attributes(attributes)
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
        format.js { render :json => { :avatarUrl => ( AvatarService.avatar_image_url(@person) )} }
      end
    else
      respond_to do |format|
        format.js { render :nothing => true, :status => 500 }
      end
    end
  end

end
