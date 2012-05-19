class WidgetsController < ApplicationController
  # Widget
  #   src: source of the data for the widget
  #   dom: what dom element to replace with the results on the users page.
  #   styled: user must set a value of 0 to turn off styling. Defaults to a styled widget.
  def cc_widget
    @data_source = params[:src]
    @dom_id = params[:dom] || 'civic-commons-widget'
    @styled = !(params[:styled] == "0")

    respond_to do |format|
      format.js{render :template => '/widgets/cc_widget.js'}
    end
  end
end
