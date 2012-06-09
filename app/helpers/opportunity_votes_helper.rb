module OpportunityVotesHelper
  
  def js(data)
    if data.respond_to? :to_json
      data.to_json
    else
      data.inspect.to_json
    end
  end
  
  def add_object_link(name, form, object, partial, where, options={})
    options = {:parent => true}.merge(options)
    html = render(:partial => partial, :locals => { :form => form}, :object => object)
    link_to_function name, %{
      var new_object_id = new Date().getTime() ;
      var html = $(#{js html}.replace(/index_to_replace_with_js/g, new_object_id)).hide();
      html.appendTo($("#{where}")).slideDown('fast');
      init_opportunity_vote_option(html);
    }, options
  end
  
  def opportunity_vote_tab_nav(step)
    selected_option_ids = @vote_response_presenter && @vote_response_presenter.selected_option_ids.join(',')
    select_options_link = (step == 'select_options') ? '#' : select_options_conversation_vote_path(@conversation,@vote, :selected_option_ids => selected_option_ids)
    render :partial => 'vote_tab_nav', :locals => {:step => step, :select_options_link => select_options_link}
  end
  
end
