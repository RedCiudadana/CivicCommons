//authentication
jQuery(function ($) {

  function popupCenter(url, width, height, name) {
    var left = (screen.width/2)-(width/2);
    var top = (screen.height/2)-(height/2);
    return window.open(url, name, "menubar=no,toolbar=no,status=no,resizable=yes,width="+width+",height="+height+",left="+left+",top="+top);
  }

  $(document).ready(function() {
    
    $("a.createacct-link.facebook-auth, a.connectacct-link.facebook-auth:not(.disconnect-fb)").live('click', function(e) {
      popupCenter($(this).attr("href"), $(this).attr("data-width"), $(this).attr("data-height"), "authPopup");
      e.stopPropagation(); return false;
    });

    $('.fb-modal a.cancel')
    .live('click',function(){
      $.colorbox.close();
      return false;
    });

    $('.fb-modal a.confirm-facebook-unlinking, a.connectacct-link.facebook-auth.disconnect-fb')
    .live('click',function(){
      $.colorbox({href:$(this).attr('href')});
      return false;
    });

    /*
      conflicting_email modal dialog
    */
    $('.fb-cnct-links a.overwrite-email').live('click',function(){
       $.post($(this).attr('href'),function(){
         $.colorbox({href:'/authentication/fb_linking_success'});
       });
      return false;
    });

    $('.fb-cnct-links a.cancel-overwrite-email').live('click',function(){
      $.colorbox({href:'/authentication/fb_linking_success'});
      return false;
    });

    $('form#ajax-auth-update-form')
    .live('ajax:success', function(evt, xhr, status, error){
      $(this).html(xhr);
    });

    $('#auth-before-facebook-unlinking') 
    .live('ajax:success', function(evt, xhr, status, error){
      $(this).replaceWith(xhr);
    });

  });
});
