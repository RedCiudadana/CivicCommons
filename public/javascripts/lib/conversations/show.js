(function () {
  $ = this.jQuery;
  $.fn.extend({

    bindContributionFormEvents: function($clicked,$tabStrip){
      var form = new ContributionTool({
        el: this, 
        tabStrip: $tabStrip,
        clicked: $clicked
      });
      $(form.el)
        .bind("ajax:success", function(evt, data, status, xhr){
          var $this = $(this);
          // apparently there is no way to inspect the HTTP status returned when submitting via iframe (which happens for AJAX file/image uploads)
          //  so, if file/image uploads via this form will always trigger ajax:success even if action returned error status code.
          //  But for this action, successes always return HTML and failures return JSON of the error messages, so we'll test if response is JSON and trigger failure if so
          try{
            $.parseJSON(data); // throws error if data is not JSON
            return $(this).trigger('ajax:complete').trigger('ajax:error', xhr, status, data); // only gets to here if JSON parsing was successful, meaning data is error messages
          }catch(err){
            // do nothing
          }
          var preview = this.getAttribute('data-preview'),
              divId = $tabStrip.attr('id'),
              $responseNode;

          if( $this.data('remotipartSubmitted') == 'script' ) {
            $responseNode = $($("<div />").html(xhr.responseText).text()); // this is needed to properly unescape the HTML returned from doing the jquery.form plugin's ajaxSubmit for some reason
          } else {
            $responseNode = $(xhr.responseText);
          }

          if(preview == "true") {
            var previewTab = '#' + divId + '-preview',
                // populate the preview div with a preview and a filled-in form with data-preview = false so it can be submitted again
                previewPane = $this.closest('div').siblings('.contribution-preview');

            // bind these ajax handlers to preview form, also add reference to this form on the new preview form
            previewPane.html($responseNode).find('form').bindContributionFormEvents($clicked,$tabStrip).data('origForm',$this);

            $this.find('.validation-error').html(''); // clear any previous errors from form
            $tabStrip.easytabs('select','li.preview-tab').find(".contribution-preview").find("a.cancel").click(function(e){
              $tabStrip.easytabs('select', $(this).attr("href"));
              e.preventDefault();
            });
          } else {
            var optionsTab = '#' + divId + '-options',
                origForm = $this.data('origForm');

            $clicked.appendContributionToThread($responseNode);
            $.fn.colorbox.close();
            setTimeout(function(){ $responseNode.scrollTo(); }, 250);
          }
        })
        .bindValidationErrorOnAjaxFailure()
        return this;
      },

      appendContributionToThread: function($responseNode) {
        var $target = this.closest('.contribution-container').find('ol.thread-list,ul.thread-list').first(),
            contribution = $responseNode.children('li').attr('id'),
            $contributionOnPage = $target.find('li#' + contribution);

        if ( $contributionOnPage.size > 0 ){
          $contributionOnPage = $contributionOnPage.replaceWith($responseNode);
        } else {
          $contributionOnPage = $target.append($responseNode);
        }
        return $contributionOnPage;
      },

      applyEasyTabsToTabStrip: function() {
        var $container = this;

        if ( $container.length == 0 ) return this;

        $container
          .resizeResponseInputs()
          .easytabs({
            tabActiveClass: 'tab-active',
            tabActivePanel: 'panel-active',
            tabs: '> .tab-area > .tab-strip-options > ul > li',
            defaultTab: '.default-tab',
            animationSpeed: 250,
            updateHash: false
          })
        .live("easytabs:after", function(){
            resizeColorbox();
          });
      },

      resizeResponseInputs: function() {
        var $container = this,
            $tabs = $container.find('.tab-strip-options'),
            $horizontalAdjust = $container.find('div.panels,label,textarea'),
            $verticalAdjust = $container.find('textarea');

        $horizontalAdjust.each(function() {
          var $this = $(this),
              horizontalPadding = parseFloat($this.css('paddingLeft')) + parseFloat($this.css('paddingRight')),
              horizontalBorder = $this.outerWidth() - $this.innerWidth();

          $this.width( $container.innerWidth() - $tabs.outerWidth() - horizontalPadding - horizontalBorder - 2 );
        });
        $verticalAdjust.each(function() {
          var $this = $(this),
            verticalPadding = parseFloat($this.css('paddingTop')) + parseFloat($this.css('paddingBottom')),
            verticalBorder = $this.outerWidth() - $this.innerWidth(),
            $sibling = $(this).siblings('label').first(),
            extraVerticalSpace = 0;

          if ( $sibling.size() > 0 ) {
            extraVerticalSpace = $sibling.outerHeight();
          }

          $this.height( $tabs.outerHeight() - verticalPadding - verticalBorder - extraVerticalSpace );
        });
        return $container;
      },

      bindValidationErrorOnAjaxFailure: function() {
        this.bind("ajax:error", function(evt, xhr, status, error){
          try{
            var errors = $.parseJSON(xhr.responseText);
          }catch(err){
            var errors = ["Please reload the page and try again"];
          }
          var errorString = "There were errors with the submission:\n<ul>";
          for(error in errors){
            errorString += "<li>" + errors[error] + "</li> ";
          }
          errorString += "</ul>"
          $(this).find(".validation-error").html(errorString);
          setTimeout(function(){
            resizeColorbox(); // need to delay this a little to give the new html a chance to be appended in the DOM
          }, 100);
        });
        return this;
      },

      liveAlertOnAjaxFailure: function() {
        this.live("ajax:error", function(evt, xhr, status, error){
          try{
            var errors = $.parseJSON(xhr.responseText);
          }catch(err){
            var errors = {msg: "Please reload the page and try again"};
          }
          var errorString = "There were errors loading the edit form:\n\n";
          for(error in errors){
            errorString += errors[error] + "\n";
          }
          alert(errorString);
        });
        return this;
      },

      maskChildOnSubmit: function($container) {
        if($container == undefined) { $container = this; }
        this
          .bind("ajax:loading", function(){
            $container.mask("Loading...");
          })
          .bind("ajax:complete", function(){
            $container.unmask();
          });
        return this;
      },

      changeTextOnLoading: function(options) {
        var opts = $.extend({}, {
          loadText: "Loading...",
          completeText: function(){
            $(this).data('origText');
          }
        }, options);

        this
          .live("ajax:loading", function(){
            var $this = $(this);
            if ( $this.data('origText') == null ) { $this.data('origText', $this.text()); }
            $this.text(opts.loadText);
          })
          .live("ajax:complete", function(evt, xhr){
            $(this).text(opts.completeText);
          });
        return this;
      },

      applyToggleToElement: function(target,altText){
        var $clicked = $(this),
            altText = altText || "Hide";
        $clicked.toggle(
        	function(){
        		$clicked.text($clicked.data('origText'));
        		$clicked.data('expanded', false);
        		$(target).slideUp();
        	},
        	function(){
        		$clicked.text(altText);
        		$clicked.data('expanded', true);
        		$(target).slideDown();
        	}
        );
      }

  });


  resizeColorbox = function(){
    $.colorbox.resize({
      innerHeight: $('#cboxLoadedContent').children().first().outerHeight() + 30
    });
  };

  $('.delete-contribution-action')
    .changeTextOnLoading({
      loadText: "Deleting..."
    })
    .live("ajax:success", function(evt, data, status, xhr){
      var $target = $(this.getAttribute("data-target"));
      $target.hide('puff', 1000);
    })
    .liveAlertOnAjaxFailure();

  $('.edit-contribution-action')
    .changeTextOnLoading()
    .live("ajax:success", function(evt, data, status, xhr){
      var $this = $(this);
      var $target = $(this.getAttribute("data-target"));

      $form = $target.html(xhr.responseText).find('form');
      new ContributionTool({el: $form});
      $form
        .bind("ajax:success", function(evt, data, status, xhr){
          var $responseNode;
          $responseNode = $(xhr.responseText);
          contributionContent = $responseNode.html();
          $target.html(contributionContent);
        })
        .bindValidationErrorOnAjaxFailure();
      init_tiny_mce($form.find('textarea.tinymce'));
    })
    .liveAlertOnAjaxFailure();

  $('.conversation-action').live('click', function(e){
    var $this = $(this);
    $.colorbox({
      transition: 'fade', // needed to fix colorbox bug with jquery 1.4.4
      href: $this.attr('href'),
      width: '600px',
      height: '340px',
      onComplete: function(){
        var divId = $this.attr('href').match(/div_id=([^&]+)/)[1],
            $tabStrip = $('.tab-strip#' + divId),
            $form = $tabStrip.find('form');

        $tabStrip.applyEasyTabsToTabStrip();
        $form.bindContributionFormEvents($this,$tabStrip);
      },
      opacity: 0.6
      //scrolling: false
    });
    e.preventDefault();
  });

  $(window).hashchange( function(){
    new ShowsConversations().scrollToContributionDenotedByWindowsLocationHash();
  });

  $('a.contribution-toggle')
    .live('click', function(e){
      e.preventDefault();
      var $div = $(this).closest('.collapsed, .uncollapsed'),
          s = document.documentElement.style;

      $div.find('a.contribution-toggle:first').toggleClass('active');

      if (!('textOverflow' in s || 'OTextOverflow' in s)) {
        var newDiv = $div.clone().toggleClass('collapsed uncollapsed');
        $div.replaceWith(newDiv);
      } else {
        $div.toggleClass('collapsed uncollapsed');
      }

      e.stopPropagation(); // needed to prevent repeated firing since '.collapsed .comment' are nested

  });

  $(document).ready(function() {

    new ShowsConversations().onReady();
  });

  this.ShowsConversations = function() { };

  this.ShowsConversations.prototype = {
    onReady: function() {
      $('.rating-button').ratingButton();
      this.scrollToContributionDenotedByWindowsLocationHash();
    },
    scrollToContributionDenotedByWindowsLocationHash: function() {
      $contribution = $('#show-contribution-' + ParseHashFor.contributionId());
      $contribution.scrollTo();
      $contribution.find('.collapsed a.contribution-toggle').first().trigger('click'); // trigger click event to uncollapse contribution
    }
  };
  this.ParseHashFor = {
    contributionId: function() {
      return parseInt(_.last(this.cleanHash().split('-')));
    },
    cleanHash: function() {
      return window.location.hash;
    }
  }
}).call(this);
