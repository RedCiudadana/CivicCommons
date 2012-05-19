class ActivityObserver < ActiveRecord::Observer

  observe :contribution, :conversation, :rating_group, :survey_response, 
          :petition, :petition_signature, :reflection, :reflection_comment

  def after_create(model)
    unless model.is_a?(Contribution) && !model.top_level_contribution?
      a = Activity.new(model)
      a.save
    end
  end

  def after_save(model)
    if model.is_a?(Contribution)
      if model.confirmed &&
        (
          (!model.conversation.nil? && model != model.conversation.contributions.first) ||
          (!model.issue.nil? && model != model.issue.contributions.first)
        )
        if Activity.where(item_id: model.id, item_type: 'Contribution').empty?
          a = Activity.new(model)
          a.save
        else
          Activity.update(model)
        end
      end
    else
      Activity.update(model)
    end
  end

  def before_destroy(model)
    Activity.destroy(model) if Activity.exists?(model)
  end

end
