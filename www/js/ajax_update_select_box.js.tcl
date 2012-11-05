# /packages/intranet-reporting/www/js/ajax_update_select_box.js.tcl
#
# Copyright (C) 1998-2012 various parties
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {

    Includes JS for updating a target form field (select)
    when a source form field is changed by the user. 

    This page is WIP. It will be extended whenever new 
    source/target combiniations are requested. 

    @param form_id 			
    @param source_object_type   	
    @param source_object_type   
    @param source_form_element_name	
    @param target_form_element_name	
    @param source_table_column_name 
    @param target_table_column_name

    @author klaus.hofeditz@project-open.com

} {
    form_id
    source_object_type
    target_object_type
    source_form_element_name
    target_form_element_name
    source_table_column_name
    target_table_column_name
}

switch $target_object_type {
    # Updating a projects drop down
    im_project {
	switch $source_object_type {
	    im_company {
		# Building request string that return options in json/xml format
		# Value of soource element can be found in var ${source_form_element_name}_value   
		set request_str "\"GET\",\"/intranet-reporting/xmlhttp-object-options-custom?object_type=$target_object_type&"
		append request_str "source_table_column_name=$source_table_column_name&source_form_element_name=$source_form_element_name&"
		append request_str "source_table_column_name=$source_table_column_name&source_form_element_value=\" + ${source_form_element_name}_value,true"

		set result_ds_type "xml"
	    }
	    default {
		set request_str "\"GET\",\"/intranet-rest/$target_object_type?format=xml&query=$source_table_column_name=$source_form_element_name\" ,true"
		set result_ds_type "json"
	    }
       }
    }
    default {
	set request_str "\"GET\",\"/intranet-rest/$target_object_type?format=xml&query=$source_table_column_name=$source_form_element_name\" ,true"
	set result_ds_type "json"
    }
}
