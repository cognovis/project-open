ad_page_contract {

    @author Juanjo Ruiz juanjoruizx@yahoo.es
    @creation-date 2005-02-07
    @cvs-id $Id$

} {
    object_type:notnull
    page_url:notnull
    {attribute_id ""}
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


# ******************************************************
# Form definition
# ******************************************************

db_1row get_layout_type {
    select layout_type, table_height, table_width
    from im_dynfield_layout_pages
    where object_type = :object_type
    and page_url = :page_url
} -column_array "page"

if { [empty_string_p $attribute_id] } {
    set list_sql {
	select  aa.pretty_name, fa.attribute_id
	from acs_attributes aa, im_dynfield_attributes fa
	where aa.object_type = :object_type
	and aa.attribute_id = fa.acs_attribute_id
        and fa.attribute_id not in (select attribute_id from im_dynfield_layout
                                  where page_url = :page_url and object_type = :object_type)
    }
} else {
    set list_sql {
	select  aa.pretty_name, fa.attribute_id
	from acs_attributes aa, im_dynfield_attributes fa
	where aa.object_type = :object_type
	and aa.attribute_id = fa.acs_attribute_id
    }
}

set attribute_list [concat [list [list "-- Select one --" ""]] [db_list_of_lists get_attributes_not_in_page "$list_sql"]]


form::create attrib_layout
element::create attrib_layout action -datatype text -widget hidden

element::create attrib_layout object_type -datatype text -widget hidden -value $object_type
element::create attrib_layout page_url -datatype text -widget hidden -value $page_url
element::create attrib_layout attribute_id -label "[_ intranet-dynfield.Attribute]" -datatype integer \
	-widget select -options $attribute_list

if { $page(layout_type) == "absolute" } {
    element::create attrib_layout class -label "[_ intranet-dynfield.Class]" -datatype text \
	    -html {size 20 maxlength 200} -help_text "[_ intranet-dynfield.Enter_the_css_class_name]"
    element::create attrib_layout sort_key -datatype text -widget hidden -value ""
} else {
    element::create attrib_layout class -datatype text -widget hidden -value ""
    element::create attrib_layout sort_key -label "[_ intranet-dynfield.Sort_key]" -datatype integer -html {size 4 maxlength 20}
}

# -------------------------------------------
# Prepopulate form
# -------------------------------------------

if { [form is_request attrib_layout] } {
    if { ![empty_string_p $attribute_id] } {
	set sql_get_attribute "select fl.class, fl.sort_key, aa.attribute_name \
		from IM_DYNFIELD_LAYOUT fl, ACS_ATTRIBUTES aa, IM_DYNFIELD_ATTRIBUTES fa \
		where fa.attribute_id = :attribute_id \
		and aa.attribute_id = fa.acs_attribute_id \
		and fa.attribute_id = fl.attribute_id \
		and fl.object_type = :object_type \
		and fl.page_url = :page_url"

	if { [db_0or1row get_attribute $sql_get_attribute] } {
	    set action update
	    element::set_properties attrib_layout attribute_id -value $attribute_id -mode view
	    element::set_value attrib_layout class $class
            element::set_value attrib_layout sort_key $sort_key
	} else {
	    set action add
	}
    } else {
	set action add
    }
    element::set_value attrib_layout action $action
}

#------------------------------------------------------
# Adp variables
#------------------------------------------------------

if { [info exists action] && $action == "update" } {
    set title "[_ intranet-dynfield.Attribute_update]"
} else {
    set title "[_ intranet-dynfield.Add_new_attribute]"
}
set context [list [list "object-types" "[_ intranet-dynfield.Object_Types]"] [list "[export_vars -base "layout-manager" {object_type}]" "[_ intranet-dynfield.object_type_pretty_name_layout]"] [list "[export_vars -base "layout-position" {object_type page_url}]" "[_ intranet-dynfield.Attributes_in_page_url]"] $title]


# ******************************************************
# Form validation
# ******************************************************

if { [form is_valid attrib_layout] } {
    form get_values attrib_layout
    
    if { $action == "add" } {
	db_dml insert_attribute {
	    insert into im_dynfield_layout
	    (attribute_id, page_url, object_type, sort_key, class)
            values
            (:attribute_id, :page_url, :object_type, :sort_key, :class)
	}
    } else {
	db_dml update_attribute {
	    update im_dynfield_layout
	    set sort_key = :sort_key, class = :class
	    where attribute_id = :attribute_id and page_url = :page_url and object_type = :object_type
	}
    }

    ad_returnredirect "layout-position?[export_vars {object_type page_url}]"
}
