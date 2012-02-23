(function(){
  var jQuery = window.CivicCommonsLoadedJquery; //get CivicCommons' loaded Jquery

  jQuery(document).ready(function($) {
    $('.civic-commons-widget-container .load-more').click(function(){
      var load_more = this;
      var base_url = this.getAttribute('href');
      var page_boundary = $(this).siblings('span.pagination-data:last')[0];
      // get the page, or return a default page number
      try{
        var page = page_boundary.getAttribute('data-page');
      }catch(e){
        var page = 1;
      }
      var jsonp_url = base_url + ".embed?hide_container=true&callback=?&page="+(parseInt(page) + 1);

      $.getJSON(jsonp_url, function(data) {
          $(load_more).before(data.html);
          if(data.next_page != true){
            $(load_more).remove();
          }
        });
      return false;
    })

  });
})();//executing the js immediately
