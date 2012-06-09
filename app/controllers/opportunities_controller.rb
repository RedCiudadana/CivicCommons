class OpportunitiesController < ApplicationController
  layout 'category_index'

  # Just require the user all the time. It's easier since while this controller
  # serves up mockups
  before_filter :require_user

  def index
    # renders the menu to see all the wireframe pages
  end

  def converse
  end

  def take_action
  end

  def reflect
  end

  def new_reflection
  end

  def reflection_permalink
  end

  def new_petition
  end

  def petition_permalink
  end

  def new_vote
  end

  def vote_permalink_step_1
  end

  def vote_permalink_step_2
  end

end

