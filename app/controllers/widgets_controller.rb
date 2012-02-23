class WidgetsController < ApplicationController
  def cc_widget
    @data_source = params[:src]
    @dom_id = params[:dom] || 'civic-commons-widget'
    respond_to do |format|
      format.js{render :template => '/widgets/cc_widget.js'}
    end
  end
end
