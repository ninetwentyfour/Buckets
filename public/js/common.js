var list_string = $.trim($('.solution_list').text());
list_string = list_string.substring(0, list_string.length - 1)
var list = list_string.split(',');
$.each(list, function() {
	$('.ordered_solution').append('<li>'+this+'</li>');
});