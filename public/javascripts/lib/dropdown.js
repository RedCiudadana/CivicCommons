$(document).ready(function() {
  $('.dropdown-toggle').click(function (e) {
    $(this).next('.dropdown-menu').slideToggle('fast');
    e.preventDefault();
  });

  // Looking into combining these into one function
  $('.js-grid-search').focusin(function() {
    $(this).siblings('.dropdown-menu').slideDown('fast');
  });

  $('.js-grid-search').focusout(function() {
    $(this).siblings('.dropdown-menu').slideUp('fast');
  });

});
