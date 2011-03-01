# /packages/intranet-dynfield/www/layout-adp.tcl
ad_page_contract {

    @author Juanjo Ruiz juanjoruizx@yahoo.es
    @creation-date 2005-02-07
    @vss $Workfile: layout-adp.tcl $ $Revision: 1.3 $ $Date: 2006/04/07 23:07:39 $
    @cvs-id $Id: layout-adp.tcl,v 1.3 2006/04/07 23:07:39 cvs Exp $

} {
    object_type:notnull
    page_url:notnull
}

# ******************************************************
# Default & Security
# ******************************************************

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "[_ intranet-dynfield.You_have_insufficient_privileges_to_use_this_page]"
    ad_script_abort
}

acs_object_type::get -object_type $object_type -array "object_info"
set object_type_pretty_name $object_info(pretty_name)
set adp_dir "[acs_package_root_dir intranet-dynfield]/resources/forms/"

set attribute_list [list]
db_multirow attributes get_object_attributes {
    select
        aa.attribute_name,
        aa.pretty_name,
        aa.pretty_plural,
        aa.table_name,
        aa.attribute_id as acs_attribute_id,
        fa.attribute_id as dynfield_attribute_id,
        fa.widget_name,
        w.widget_id,
        w.widget
    from
        acs_attributes aa,
        im_dynfield_attributes fa,
        im_dynfield_widgets w
    where
        aa.object_type = :object_type
        and aa.attribute_id = fa.acs_attribute_id
        and fa.widget_name = w.widget_name
} {
    lappend attribute_list $attribute_name
}


# ******************************************************
# Form definition
# ******************************************************

form::create layout-adp

element::create layout-adp object_type -datatype text -widget hidden -value $object_type
element::create layout-adp page_url -datatype text -widget hidden -value $page_url

element::create layout-adp adp_file -label "[_ intranet-dynfield.Adp_file]" -datatype text -widget text \
	-html {size 20 maxlength 400}
element::create layout-adp action -datatype text -widget hidden
element::create layout-adp content -label "[_ intranet-dynfield.Content]" -datatype text -widget textarea \
	-html {rows 15 cols 100} -nospell

if { [form is_request layout-adp] } {
    set file_name [db_string get_filename {
	select adp_file from im_dynfield_layout_pages
	where object_type = :object_type
	and page_url = :page_url
    } -default ""]
    if { ![empty_string_p $file_name] } {
	set action update
        element::set_properties layout-adp adp_file \
		-help_text "[_ intranet-dynfield.This_file_is_located_in] '${adp_dir}'" -value $file_name \
		-mode view 
    } else {
	set action insert
	# read default file
	set file_name [parameter::get -parameter default_adp_form_file -default "subtemplate"]
	
	element::set_properties layout-adp adp_file \
		-help_text "[_ intranet-dynfield.This_file_will_be_placed_in] '${adp_dir}'"
    }

    if [catch {
	set file_stream [open "${adp_dir}${file_name}.adp" r]
	set file_content "[read $file_stream]"
	close $file_stream
	element::set_value layout-adp content $file_content
    } errmsg] {
	ns_log WARNING "layout-adp.tcl ------------------------> file does not exist '${adp_dir}${file_name}' or $errmsg"
    }

    element::set_value layout-adp action $action
}


# ******************************************************
# Adp variables
# ******************************************************

if { ![form is_request layout-adp] && ![form is_valid layout-adp] } {
    set action [element get_value layout-adp action]
}

if { [info exists action] && $action == "update" } {
    set title "[_ intranet-dynfield.Edit_the_form_adp_file]"
} else {
    set title "[_ intranet-dynfield.Create_a_new_adp_file_for_this_form]"
}
set context [list [list "object-types" "Object Types"] [list "[export_vars -base "layout-manager" {object_type}]" "$object_type_pretty_name layout"] $title]


# ******************************************************
# Form validation
# ******************************************************
if { [form is_valid layout-adp] } {
    form get_values layout-adp
    
    # no duplicated filename
    if { [file extension adp_file] != ".adp" } {
	append adp_file ".adp"
    }
    if { $action == "insert" && [file exists "${adp_dir}${adp_file}"]} {
	element::set_error layout-adp adp_file "[_ intranet-dynfield.This_file_already_exists]"
	return
    }
    
    
    # make sure that all id's in adp exist
    
    set error_ids 0
    set list_error_id [list]
    set content_tmp $content
    
    #look for the first id, mark it, and go the next one, untill there is no more
    while { [regexp {id=\"([^\"]*)\"} $content_tmp match field_id]} {
	regsub {id=\"([^\"]*)\"} $content_tmp {(\1)} content_tmp
	if { [lsearch -exact $attribute_list $field_id] == "-1" && [lsearch -exact $list_error_id $field_id] == "-1" } {
	    incr error_ids
	    lappend list_error_id $field_id
	}
    }
    
    # We can not check this because now the user can add core (not DynField) attributes and 
    # there is no easy way to know wich ones are the core attributes in a particular page
    #if { $error_ids } {
	#element::set_error layout-adp content "[_ intranet-dynfield.Revise_your_attributes_id] 
	#<ul><li>[join $list_error_id "<li>"]</ul>"
	#return
    #}
    
    
    # save file
    if { $action == "insert" } {
	set adp_stream [open "${adp_dir}${adp_file}" w]
	puts -nonewline $adp_stream $content
	close $adp_stream

	# remove file extension
	regsub {.adp} $adp_file {} adp_file
	db_dml insert_filename {
	    update im_dynfield_layout_pages
	    set adp_file = :adp_file
	    where object_type = :object_type
	    and page_url = :page_url
	}
    } elseif { $action == "update" } {
	set adp_stream [open "${adp_dir}${adp_file}" w]
        puts -nonewline $adp_stream $content
        close $adp_stream
    }

    ad_returnredirect [export_vars -base "layout-manager" { object_type }]
}

ad_return_template

