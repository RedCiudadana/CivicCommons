require 'gchart'

class VoteProgressService
  include ActionView::Helpers::AssetTagHelper
  include ActionView::Helpers::TagHelper
  include ActionView::Helpers::TextHelper
  
  attr_accessor :survey, :progress_result, :total_weighted_votes, :highest_weighted_votes_percentage, :voter
  delegate  :max_selected_options, 
            :to => :survey
  
  DEFAULT_CHART_COLORS = %w(EFD279 95CBE9 024769 AFD775 2C5700 DE9D7F 097054 FFDE00 6599FF FF9900 FFC6A5 FFFF42 DEF3BD 00A5C6 DEBDDE)
  
  def initialize(survey, voter = nil)
    @survey = survey
    calculate_progress
    calculate_weighted_votes_percentage
    get_voted_options_by_voter(voter) if voter
  end
  
  def get_voted_options_by_voter(voter)
    response = @survey.survey_responses.find_by_person_id(voter.id)
    if response
      selected_option_id = response.selected_survey_options.collect(&:survey_option_id)
      progress_result.each_with_index do |record, index| 
        record.voted = true if selected_option_id.include?(record.survey_option_id)
      end
    end
  end
    
  def render_chart
    chart = GChart.bar do |g|
        g.title = 'Vote Results'
        g.data   = formatted_weigthed_votes
        g.colors = DEFAULT_CHART_COLORS
        g.legend = progress_result.collect{|record| record.title}
        g.orientation = :horizontal
        g.width  = 450
        g.height = (progress_result.count * 40) + 60
        g.thickness = 20
        g.spacing = 2
        g.grouped = false
        g.axis(:left) { |a| a.labels = progress_result.collect{|record| pluralize(record.weighted_votes.to_i, 'Point', 'Points')}.reverse}
        g.extras = {'chdlp'=>'tv',            # Positioning of legend
                    'chma' => '20,20,20,20',  # Margin
                    'chf'=>'bg,s,FFFFFF00',   # Transparant background
                    'chts' => '000000,18,l'   # Align Title to the left
                    } 
      end
    image_tag chart.to_url, :class => 'google-chart'
  end
    
  def total_weighted_votes
    @total_weighted_votes ||= calculate_total_weighted_votes
  end
  
  def calculate_total_weighted_votes
    progress_result.inject(0){|sum,record| sum + record.weighted_votes.to_i}
  end
  
  def calculate_weighted_votes_percentage
    progress_result.each_with_index do |record, index| 
      weighted_vote_num = record.weighted_votes.to_f / total_weighted_votes.to_f
      record.weighted_votes_percentage = (weighted_vote_num.nan? ? 0 : weighted_vote_num * 100).to_i 
      record.winner = true if index < max_selected_options
    end
    @highest_weighted_votes_percentage = progress_result.collect(&:weighted_votes_percentage).max
  end
  
  def calculate_progress
    # Calculation of survey results based on weigthed points on the order of selected options.
    # If Max Selected Options is 3, then the first selected option is assigned a 3 point.
    # the second selected option is assigned 2 points, and the third, 1 point.
    # To get the weigthed_votes, we multiply the weigth(points) with the number of times a particular option have been selected.
    progress_sql = <<-SQL
      SELECT s.id AS survey_id, so.id AS survey_option_id, so.title, so.description,
      COALESCE(SUM(s.max_selected_options - (sso.position) + 1),0) AS weighted_votes,
      COUNT(sso.id) AS total_votes
      FROM surveys s RIGHT JOIN survey_options so 
      ON s.id = so.survey_id 
      LEFT JOIN selected_survey_options sso
      ON sso.survey_option_id = so.id
      WHERE so.survey_id = #{survey.id}
      GROUP BY so.id
      ORDER BY weighted_votes DESC
    SQL
    @progress_result =  SurveyOption.find_by_sql(progress_sql)
  end
  
  def formatted_weigthed_votes
    VoteProgressService.format_data(progress_result.collect{|record| record.weighted_votes})
  end
  
  def self.format_data(data=[])
    #turns one dimensional array into multi dimensional array needed for the google chart
    # from :
    #  [1,2,3]
    # into :
    #  [
    #   [1,0,0], 
    #   [0,2,0],
    #   [0,0,3]
    #  ]
    formatted_data = []
    data.each_with_index do |col, index|
      d = []
      data.length.times do |i|
        d[i] = (i == index) ? col : 0
      end
      formatted_data << d
    end
    return formatted_data
  end
  
end