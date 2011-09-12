module SurveysHelper
  def relative_weighted_votes_percentage(weighted_votes_percentage, highest_weighted_votes_percentage, offset=0)
    total = (weighted_votes_percentage.to_f / highest_weighted_votes_percentage.to_f) * 100
    total = total + offset if total > offset.abs
    return total.to_i
  end
  
  def back_to_surveyable(survey)
    if !survey.surveyable_type.blank? && !survey.surveyable_id.blank?
      case survey.surveyable
      when Issue
        surveyable = survey.surveyable.becomes(Issue)
        title = survey.surveyable.name
      when Conversation
        surveyable = survey.surveyable
        title = survey.surveyable.title
      end
      raw "Back to: #{link_to title, surveyable}"
    end
  end
end