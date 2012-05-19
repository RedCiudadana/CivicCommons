var lastAjaxSettings;

(function ($) {
  $.fn.extend({
    scrubPlaceholderText: function(){
      $(this).find('input[placeholder], textarea[placeholder]').each( function() {
        $this = $(this);
        if( $this.val() == $this.attr('placeholder') ){
          $this.val('');
        }
      });
    },
    scrollTo: function(){
      var $this = this;
      if(this.offset() == undefined) { return; }
      var top = this.offset().top - 100; // 100px top padding in viewport,
      var origBG = this.css('background') || 'transparent';
      var scrolled = false; // Hack since 'html,body' is the only cross-browser compatible way to scroll window

      $('html,body').animate({scrollTop: top}, 1000, function (){
        if ( ! scrolled ) { $this.effect('highlight', {color: '#c5d36a'}, 3000); }
        scrolled = true;
      });
      return $this;
    }
  });
})(jQuery);

jQuery(function ($) {

  // Log all jQuery AJAX requests to Google Analytics
  $(document).ajaxSend(function(event, xhr, settings){
    if(typeof(_gaq) != 'undefined') {
      _gaq.push(['_trackPageview', settings.url]);
      if ( settings.url != "/people/ajax_login" ) {
        lastAjaxSettings = settings;
        lastAjaxEvent = event;
        lastAjaxIsColorbox = $('#colorbox').is(':visible');
      }
    }
  });

  $('#ajax-login-form')
  .live('ajax:error', function(evt, xhr, status, error){
    alert('Login failed!');
  });


});

$(document).ready(function(){
  $('a[data-colorbox]:not([data-remote])').live('click', function(e){
    $.colorbox({
      transition: 'fade', // needed to fix colorbox bug with jquery 1.4.4
      href: $(this).attr('href')
    });
    e.preventDefault();
  });

  $('.flash-notice').show('blind');
  setTimeout(function(){
    $('.flash-notice').hide('blind');
  },5000);

  // set defaults for CKEditor
  if('CKEDITOR' in window) {
    CKEDITOR.on('dialogDefinition', function(event) {
      var dialogName = event.data.name;
      var dialogDefinition = event.data.definition;

      if(dialogName == 'link') {
        var targetTab = dialogDefinition.getContents('target');
        var targetField = targetTab.get('linkTargetType');
        targetField['default'] = '_blank';
      }

      if(dialogName == 'image') {
        var uploadPageID = 'Upload';
        dialogDefinition.removeContents('advanced');
        dialogDefinition.removeContents('Link');

        if(ckDialogPageExists(dialogDefinition, uploadPageID)) {
          var oldMethod = dialogDefinition.onShow;
          var oldArguments = arguments;

          dialogDefinition.onShow = function() {
            this.selectPage(uploadPageID);
            this.on('selectPage', ckRemoveLoadIcon);
            if(typeof oldMethod == 'function') {
              oldMethod.apply(this, oldArguments);
            }

            var uploadButton = this.getContentElement('Upload', 'uploadButton');
            var $uploadButton = $('#' + uploadButton.domId);

            // if the span for the button recieves 'upload-complete' it will dismiss the loading icon
            $uploadButton.bind('upload-complete', function(event){
              $(this).find('.loading-icon').remove();
            });

            $uploadButton.click(function(event){
              if(event.currentTarget == this &&
                $(this).find('.loading-icon').length === 0 &&
                CKEDITOR.dialog.getCurrent().getContentElement('Upload', 'upload').getValue() !== '') {
                var $spinner = $('<img class="loading-icon" src="/images/loading.gif" style="padding-left: 5px; vertical-align: middle;" />');
                $(this).find('span').append($spinner);
              }
            });
          };
        }
      }
    });
  }
});

function ckRemoveLoadIcon() {
  var $button = $('span.cke_dialog_ui_button:contains("Send it to the Server")');
  $button.trigger('upload-complete');
}

function ckDialogPageExists(dialogDefinition, pageID) {
  var i = 0;
  for(i = 0; i < dialogDefinition.contents.length; i++) {
    if(dialogDefinition.contents[i].id === pageID) {
      return true;
    }
  }
  return false;
}

var civic = function() {
  var displayMessage = function(message, cssClass) {
    var messageDiv = $("<div>")
      .addClass(cssClass)
      .addClass("message")
      .text(message)
      .appendTo($("body"));

    setTimeout(function() { messageDiv.fadeOut();}, 4000);
  };
  var self = {};
  self.error = function(message) { displayMessage(message, "error"); };
  self.alert = function(message) { displayMessage(message, "alert"); };
  return self;
}();

