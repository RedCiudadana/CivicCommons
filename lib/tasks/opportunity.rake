namespace :opportunity do

  desc 'create Opportunities from existing Conversation data'
  task :migrate => :environment do
		Conversation.all.each do |conversation|
  		if conversation.valid?
  			Opportunity.new(conversation: conversation).save
  		end
  	end
  end
end