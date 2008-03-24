ad_page_contract {

    @author Juanjo Ruiz juanjoruizx@yahoo.es
    @author Frank Bergmann <frank.bergmann@project-open.com>
    @creation-date 2008-02-07
    @cvs-id $Id$

} {
    object_type:notnull
    page_url:notnull
    orderby:optional
    {action ""}
}

# ******************************************************
# Default & Security
# ******************************************************

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]

if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    ad_script_abort
}

set return_url "[ad_conn url]?[ad_conn query]"
set return_url_encoded [ns_urlencode $return_url]

acs_object_type::get -object_type $object_type -array "object_info"

set object_type_pretty_name $object_info(pretty_name)

set title "Attributes in $page_url"
set context [list [list "object-types" "Object Types"] [list "[export_vars -base "layout-manager" {object_type}]" "$object_type_pretty_name layout"] $title]

# ******************************************************
# Action
# ******************************************************

switch $action {
    add_all_attributes {
	# create a copy of the default layout
	set org_page_url $page_url
	set sql "
		select distinct
			dl.*
		from 
			im_dynfield_layout_pages dlp,
			im_dynfield_layout dl,
			im_dynfield_attributes da,
			acs_attributes aa
		where
			dlp.page_url = dl.page_url and
			dl.attribute_id = da.attribute_id and
			da.acs_attribute_id = aa.attribute_id and
			dl.page_url = 'default' and
			aa.object_type = :object_type
        "
	db_foreach all_attrib $sql {
	    set exists_p [db_string exists "
		select	count(*) 
		from	im_dynfield_layout 
		where	attribute_id = :attribute_id and page_url = :org_page_url
	    "]
	    if {!$exists_p} {
		    db_dml insert "
			insert into im_dynfield_layout (
				attribute_id, page_url,
				pos_x, pos_y, size_x, size_y,
				label_style, div_class, sort_key
			) values (
				:attribute_id, :org_page_url,
				:pos_x, :pos_y, :size_x, :size_y,
				:label_style, :div_class, :sort_key
			)
		    "
	    }
	}
	set page_url $org_page_url
    }
}

# ******************************************************
# List definition
# ******************************************************

db_1row get_layout_type {
	select	*
	from	im_dynfield_layout_pages
	where	object_type = :object_type
		and page_url = :page_url
} -column_array "page"

lappend action_list "Add attribute" "[export_vars -base "layout-position-2" { object_type page_url }]" "Add item to this order"
lappend action_list "Add all attributes" "[export_vars -base "layout-position" { object_type page_url {action add_all_attributes}}]" "Add all available attributes"
set no_data "[_ intranet-dynfield.No_attributes_added_to_this_page]"


set element_list {
    pretty_name {
	label "Pretty Name"
    }
    pos_y {
	label "Y Pos"
    }
    pos_x {
	label "X Pos"
    }
    size_x {
	label "X Size"
    }
    size_y {
	label "Y Size"
    }
    label_style {
	label "Label<br>Style"
    }
    div_class {
	label "Div<br>Class"
    }
    attrib_edit {
	label ""
	display_template "<a href=@attrib_layout.edit_url@ class=button>#acs-kernel.common_Edit#</a>"
    }
    attrib_delete {
	label ""
	display_template "<a href=@attrib_layout.delete_url@ class=button>#acs-kernel.common_Delete#</a>"
    }
}


list::create \
    -name attrib_list \
    -multirow attrib_layout \
    -key attribute_id \
    -actions $action_list \
    -no_data $no_data \
    -orderby {
	pretty_name {orderby pretty_name}
	object_type {orderby object_type}
	class {orderby class}
	sort_key {orderby sort_key}
	pos_y {orderby pos_y}
	pos_x {orderby pos_x}
	size_y {orderby size_y}
	size_x {orderby size_x}
	label_style {orderby label_style}
	div_class {orderby div_class}
    } \
    -filters {
	object_type {}
	page_url {}
    } \
    -elements $element_list 

db_multirow -extend { edit_url delete_url } attrib_layout get_attributes "
	select distinct
		aa.*,
		da.*,
		dl.*
	from 
		im_dynfield_layout_pages dlp,
		im_dynfield_layout dl,
		im_dynfield_attributes da,
		acs_attributes aa
	where
		dlp.page_url = dl.page_url and
		dl.attribute_id = da.attribute_id and
		da.acs_attribute_id = aa.attribute_id and
		aa.object_type = :object_type and
		dl.page_url = :page_url
	[template::list::orderby_clause -name attrib_list -orderby]
" {
	set edit_url [export_vars -base "layout-position-2" { object_type page_url attribute_id return_url }]
	set delete_url [export_vars -base "layout-position-del" { object_type page_url attribute_id return_url }]
}

