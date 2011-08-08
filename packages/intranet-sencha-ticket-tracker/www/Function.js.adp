/**
 * intranet-sencha-ticket-tracker/www/Function.js
 * General Functions
 *
 * @author David Blancon (david.blanco@grupoversia.com)
 * @creation-date 2011-08
 * @cvs-id $Id$
 *
 * Copyright (C) 2011, ]project-open[
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.
 *
 *  This program is distributed in the hope that it will be useful,
 *  but WITHOUT ANY WARRANTY; without even the implied warranty of
 *  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 *  GNU General Public License for more details.
 *
 *  You should have received a copy of the GNU General Public License
 *  along with this program.  If not, see <http://www.gnu.org/licenses/>.
 */

/**
	Trims whitespace:
		Only one whitespace between words is correct.
		Trims whitespace from either end of a string.
*/
function espaces(text){
	if (!Ext.isString(text)){
		return text;
	} 

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


function validateLevel(record,store,field){
	var record_field_value = record.get(field);
	var record_field_length = record_field_value.length;
	var validate = true;
	
	store.each(function(record){
			var store_field_value = record.get(field);
			var store_field_length = store_field_value.length;
			if (store_field_length > record_field_length && store_field_value.substring(0,record_field_length) == record_field_value) {
				validate = false;
			}
		}
	);
	return validate;
}