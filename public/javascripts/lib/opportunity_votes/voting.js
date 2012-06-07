var reset_selected_option_positions = function(){
  $('input.selected_option').each(function(i){
    var index = i + 1
    $(this).attr('name', 'vote_response_presenter[selected_option_'+ index +'_id]');
    $(this).attr('id', 'vote_response_presenter_selected_option_'+ index +'_id');
  })
}
$(document).ready(function() {
  
  //Add numbering on the li of the opportunity votes, so that it doesn't move as it is being dragged
  $(".opportunities-ballot li").each(function(n) {
    var pos = $(this).position();
    var number = document.createElement('div');
    number.innerHTML = (n+1) + ".";
    $(number).css("position", "absolute");
    $(number).addClass('number')
    $(".opportunities-ballot").append(number);
    $(number).position({
      my: "center",
      at: "left",
      of: this,
      offset: "-15 15"
    });
  });
  
  $('.opportunities-ol').sortable({
    update: reset_selected_option_positions
  });  
  

})

