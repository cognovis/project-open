# /packages/intranet-rest/www/dynfield-widget-values.tcl
#
# Copyright (C) 2010 ]project-open[
#

# ---------------------------------------------------------
# Parameters passed aside of page_contract
# from intranet-rest-procs.tcl:
#
#    [list object_type $object_type] \
#    [list format $format] \
#    [list user_id $user_id] \
#    [list object_id $object_id] \
#    [list query_hash_pairs $query_hash_pairs] \

if {![info exists user_id]} { set user_id 0 }
if {![info exists format]} { set format "html" }
set rest_url "[im_rest_system_url]/intranet-rest"

array set query_hash $query_hash_pairs

if {![info exists query_hash(widget_id)]} {
    switch $format {
	html {
	    ad_return_complaint 1 "Please specify 'widget_id'."
	    ad_script_abort
	}
	xml {
	    im_rest_error -http_status 406 -message "Parameter 'widget_id' missing, please specify"
	    return
	}
    }
}

if {0 == $user_id} {
    # User not autenticated
    switch $format {
	html {
	    ad_return_complaint 1 "Not authorized"
	    ad_script_abort
	}
	xml {
	    im_rest_error -http_status 401 -message "Not authenticated"
	    return
	}
    }
}


set widget_id $query_hash(widget_id)
set widget_values {}

db_0or1row widget_info "
	select	*,
		widget as tcl_widget
	from	im_dynfield_widgets
	where	widget_id = :widget_id
"
if {![info exists widget_name]} { 
    switch $format {
	html {
	    ad_return_complaint 1 "Invalid 'widget_id'"
	    ad_script_abort
	}
	xml {
	    im_rest_error -http_status 406 -message "Invalid 'widget_id'"
	    return
	}
    }
}


# Extract the values
switch $tcl_widget {
    generic_sql {
	# parameters contains {custom {sql {...}}}
	set custom [lindex $parameters 0]
	set sql_list [lindex $custom 1]
	set sql [lindex $sql_list 1]
	# ad_return_complaint 1 "$sql"
	set widget_values [db_list_of_lists widget_sql $sql]
	set widget_values [ns_quotehtml $widget_values]
    }
    default  {
	set message "Widget type '$tcl_widget' not implemented yet"
	switch $format {
	    html {
		ad_return_complaint 1 $message
		ad_script_abort
	    }
	    xml {
		im_rest_error -http_status 406 -message $message
		return
	    }
	}
    }
}


# Got a user already authenticated by Basic HTTP auth or auto-login
switch $format {
    xml {
	# ---------------------------------------------------------
	# Return the list of widget values
	# ---------------------------------------------------------
	
	set xml_p 1
	set xml ""
	foreach pair $widget_values {
	    append xml "<value key=\"[lindex $pair 0]\">[lindex $pair 1]</value>\n"
	}

	set xml "<?xml version='1.0' encoding='UTF-8'?>\n<widget_values>\n$xml</widget_values>\n"

    }
    default {

	set xml_p 0
	set page_title [lang::message::lookup "" intranet-rest.Dynfield_Widget_Values "Dynfield Widget Values"]
	set context_bar ""
	set dynfield_widget_values "widget_id=$widget_id"

	set html ""
	foreach pair $widget_values {
	    append html "<tr><td>[lindex $pair 0]</td><td>[lindex $pair 1]</td></tr>\n"
	}

	set html "<table>\n$html</table>\n"

	# End of HTML stuff
    }
}
	