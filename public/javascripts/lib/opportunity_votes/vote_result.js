$(document).ready(function(){
	$('.vote-bar a').click(function(e) {
	  $(this).parent().siblings('.vote-summary').slideToggle('fast');
	  e.preventDefault();
	});
});
