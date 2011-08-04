

/**
	Trims whitespace:
		Only one whitespace between words is correct.
		Trims whitespace from either end of a string.
*/
function espaces(text){
	var ar_word= text.split(' ');
	var new_text = "";
	
	for(var i=0;i<ar_word.length;i++){	
		if (ar_word[i].length > 0){
			new_text = new_text + " " + ar_word[i];
		}
	}

	return Ext.String.trim(new_text);
}

/**
	Check all the values removing whiteespaces with 'espaces' function

*/
function checkValues(values){
	for(var field in values) {
		if (values.hasOwnProperty(field)) {
			values[field]=espaces(values[field]);
		}
	}
}