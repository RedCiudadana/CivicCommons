// alert('here');
var reset_option_positions = function(){
  $('.option-position').each(function(i){
    $(this).val(i+1);
  })
};

var delete_option = function(el){
  if (confirm('Are you sure you want to delete this?')){
    $(el).closest('.survey-option').hide('fast', function(){
      $(this).remove();
    });
  }
  return false;
}

var create_option_ckeditor = function(el){
  var ck_id = $(el).attr('id');
  if(CKEDITOR.instances[ck_id]){
    CKEDITOR.instances[ck_id].destroy(true);
  }
  CKEDITOR.replace(ck_id, { cols: '40',language: 'en',rows: '10' });
}

var init_opportunity_vote_option = function(el){
  var option = $('.cktextarea',el)
  create_option_ckeditor(option);
}

var init_all_opportunity_vote_option = function(){
  $('.cktextarea').each(function(){
    create_option_ckeditor(this)
  })
}

$(document).ready(function() {
  init_all_opportunity_vote_option();
  $('#options').sortable({ 
    handle: '.sort-option',
    update: reset_option_positions,
    start: function(event,ui){
      var ck_id = $('.cktextarea', ui.item).attr('id');
      CKEDITOR.instances[ck_id].updateElement();
    },
    stop: function(event,ui){
      init_opportunity_vote_option(ui.item);
    }
  });
  
})

