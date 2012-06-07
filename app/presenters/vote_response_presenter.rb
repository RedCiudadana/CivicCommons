class VoteResponsePresenter
  attr_accessor :survey_response, :confirmed
  
  delegate  :id, :class, :errors, :to_param, :new_record?, :selected_survey_options, :selected_option_ids, :selected_option_ids=, :survey, :person, :persisted?, 
            :to => :survey_response
  delegate  :max_selected_options, :expired?,
            :to => :survey

  def initialize(options)
    person_id = options.delete(:person_id)
    survey_id = options.delete(:survey_id)
    @survey_response = SurveyResponse.find_or_initialize_by_person_id_and_survey_id(person_id, survey_id)
    
    define_methods_for_selected_options
    
    options.each_pair do |key, val|
      self.send("#{key}=".to_sym,val)
    end
  end
  
  def selected_option(opt_id)
    self.send("selected_option_#{opt_id}")
  end
  
  def confirmed?
    !!@confirmed
  end
  
  def already_voted?
    survey_response.persisted?
  end
  
  def allowed?
    !(expired? || already_voted?)
  end
  
  def available_options
    survey.options.position_sorted - selected_survey_options.collect{|record| record.survey_option}
  end
  
  def options_sorted
    survey.options.position_sorted
  end
  
  def define_methods_for_selected_options
    max_selected_options.times do |i|
      index = i+1
      
      # def selected_survey_option_1
      #   @selected_survey_option_1 ||= selected_survey_options.find_or_initialize_by_position(1) 
      # end
      define_singleton_method "selected_survey_option_#{index}" do
        if not instance_variable_defined?("@selected_survey_option_#{index}")
          instance_variable_set "@selected_survey_option_#{index}", selected_survey_options.find_or_initialize_by_position(index) 
        end
        instance_variable_get "@selected_survey_option_#{index}"
      end
      
      # def selected_option_1_id
      #   selected_survey_option_1.survey_option_id
      # end
      define_singleton_method "selected_option_#{index}_id" do
        self.send("selected_survey_option_#{index}").survey_option_id
      end
      
      # def selected_option_1_id=(val)
      #   selected_survey_option_1.survey_option_id = val
      # end
      define_singleton_method "selected_option_#{index}_id=" do |val|
        self.send("selected_survey_option_#{index}").survey_option_id = val
      end
      
      # def selected_option_1
      #   selected_survey_option_1.survey_option
      # end
      define_singleton_method "selected_option_#{index}" do
        self.send("selected_survey_option_#{index}").survey_option
      end
      
      # def selected_option_1=(obj)
      #   selected_survey_option_1.survey_option_id = obj
      # end
      define_singleton_method "selected_option_#{index}=" do |obj|
        self.send("selected_survey_option_#{index}").survey_option = obj
      end
      
      
    end
  end
  
  def valid_selected_options?
    survey_response.validate_presence_of_selected_option = true
    survey_response.valid?
    survey_response.errors[:selected_option_ids].blank?
  end

  def save
    ActiveRecord::Base.transaction do
      survey_response.save!
      max_selected_options.times do |i|
        index = i+1
        unless self.send("selected_option_#{index}_id").blank?
          self.send("selected_survey_option_#{index}").bypass_survey_option_id_uniqueness = true #bypasses the validates_uniqueness_of
          survey_response.selected_survey_options << self.send("selected_survey_option_#{index}")
        else
          self.send("selected_survey_option_#{index}").destroy
        end
        errors.add("selected_option_#{index}_id",self.send("selected_survey_option_#{index}").errors.full_messages) if self.send("selected_survey_option_#{index}").errors.any?
      end
    end
    errors.empty?
  end

end