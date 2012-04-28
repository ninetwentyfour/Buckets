//make the solved list pretty
if(window.location.pathname == "/bucket-solved"){
	var list_string = $.trim($('.solution_list').text());
	list_string = list_string.substring(0, list_string.length - 1)
	var list = list_string.split(',');
	$.each(list, function() {
		$('.ordered_solution').append('<li>'+this+'</li>');
	});
}


//handle dynamic field generation
if(window.location.pathname == "/"){
	$('#number_field').change(function() {
		$('#field_block').empty();
		var num_fields = $('#number_field').val();
		for(var i=0; i<num_fields; i++) {
			//this is ugly
			$('#field_block').append("<p class='form-field-row'><span><label for='bucket2'>Bucket "+(i + 1)+"</label></span><span class='field'><input id='"+(i + 1)+"' name='bucket["+i+"]' required='required' size='30' type='number' min='0'></span></p>");
		}
	});
}