ad_page_contract {

    @author Juanjo Ruiz juanjoruizx@yahoo.es
    @creation-date 2005-02-07
    @cvs-id $Id: layout-page.tcl,v 1.4 2008/03/24 22:35:56 cvs Exp $

} {
    object_type:notnull
    page_url:optional,notnull
    orderby:optional
}

# ******************************************************
# Default & Security
# ******************************************************

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]


if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set return_url "[ad_conn url]?[ad_conn query]"
set return_url_encoded [ns_urlencode $return_url]

acs_object_type::get -object_type $object_type -array "object_info"

set object_type_pretty_name $object_info(pretty_name)

set title "Layout definition"
set context [list [list "object-types" "Object Types"] [list "layout-manager?object_type=$object_type" "$object_type_pretty_name layout"] $title]


# ******************************************************
# Form definition
# ******************************************************

set type_list [list \
	[list "[_ intranet-dynfield.Table]" "table"] \
	[list "[_ intranet-dynfield.DIV_Absolute]" "div_absolute"] \
	[list "[_ intranet-dynfield.DIV_Relative]" "div_relative"] \
	[list "[_ intranet-dynfield.adp]" "adp"] \
]

form::create page_layout 

element::create page_layout object_type -datatype text -widget hidden -value $object_type
element::create page_layout action -datatype text -widget hidden -value add

if { [exists_and_not_null page_url] } {
    element::create page_layout page_url -datatype text -label "Page url" -mode view
    element::create page_layout layout_type -datatype text -label "Layout type" -widget select -options $type_list \
	-help_text "If you chose relative, please define the number of columns for the form" -mode view
} else {
    element::create page_layout page_url -datatype text -label "Page url" -html {size 50 maxlength 500} \
	    -help_text [_ intranet-dynfield.Use_a_relative_url_as_example]
    element::create page_layout layout_type -datatype text -label "Layout type" -widget select -options $type_list \
	-help_text "If you chose relative, please define the number of columns for the form"
}

element::create page_layout table_width -datatype integer -label "Columns" -html {size 4 maxlength 10} -optional

if { [exists_and_not_null page_url] && [form is_request page_layout] } {
    db_1row get_page_values {
	select	page_url,
		layout_type,
		table_height,
		table_width 
	from	im_dynfield_layout_pages
	where
		object_type = :object_type
		and page_url = :page_url
    }
    element::set_value page_layout page_url $page_url
    element::set_value page_layout layout_type $layout_type
    element::set_value page_layout table_width $table_width
    element::set_value page_layout action update
}


# ******************************************************
# Form validation
# ******************************************************

if { [form is_valid page_layout] } {
    form get_values page_layout

    if { $action != "update" } {
	db_transaction {	
	    db_dml insert_page {
		insert into im_dynfield_layout_pages (
			page_url, object_type, layout_type, table_width
		) values (
			:page_url, :object_type, :layout_type, :table_width
		)
	    }
	} on_error {
	    ad_return_complaint 1 "The page '$page_url' already contains the '$object_type' object type: <pre>$errmsg</pre>"
	    ns_log warning "\[TCL\]dynfield/www/layout-page --------> $errmsg"
	    ad_script_abort
	}
    } else {
	db_dml update_page {
	    update dynfield_layout_pages set table_width = :table_width
	    where page_url = :page_url and object_type = :object_type
	}
    }
    
    ad_returnredirect "layout-position?[export_vars {object_type page_url}]"
}
