ad_page_contract {

    @author Juanjo Ruiz juanjoruizx@yahoo.es
    @creation-date 2005-02-07
    @cvs-id $Id: layout-manager.tcl,v 1.3 2008/03/24 22:35:56 cvs Exp $

} {
    object_type:notnull
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

set title "Layout pages of $object_type_pretty_name"
set context [list [list "object-types" "Object Types"] $title]


# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

lappend action_list "Add page" "[export_vars -base "layout-page" { object_type }]" "Add item to this order"

list::create \
	-name layout_list \
	-multirow layout_pages \
	-key page_url \
	-actions $action_list \
	-no_data "No layout pages" \
	-elements {
    page_url { 
	label "Page" 
	link_url_col details_url
    }
    layout_type { 
	label "Type" 
        display_template {
	    <if @layout_pages.layout_type@ eq "relative">
	    <a href="@layout_pages.edit_url@" class="button">@layout_pages.layout_type@</a>
	    </if>
	    <else>
	       @layout_pages.layout_type@
	    </else>
	    }
    }
    default_p { 
	label "Default?"
        display_template {
	    <if @layout_pages.default_url@ not nil>
	    <a href="@layout_pages.default_url@" class="button">#intranet-dynfield.Set_as_the_default#</a>
	    </if>
	    <else>
	    #intranet-dynfield.Default_page#
	    </else>
	}
    }
    attrib_delete {
	label ""
	display_template {
	    <a href="@layout_pages.delete_url@" class="button">#acs-kernel.common_Delete#</a>
	}
    }
} \
	-orderby {
    page_url {orderby page_url}
    layout_type {orderby layout_type}
    default_p {orderby default_p}
} \
	-filters {
    object_type {}
}


db_multirow -extend {details_url edit_url delete_url default_url} layout_pages get_pages "
	select 
		page_url, 
		layout_type, 
		default_p
	from 
		im_dynfield_layout_pages
	where
		object_type = :object_type
	[template::list::orderby_clause -name layout_list -orderby]
" {
    if { $layout_type == "relative" } {
	set edit_url [export_vars -base "layout-page" { object_type page_url }] 
    }
    set details_url [export_vars -base "layout-position" { object_type page_url }]
    set delete_url [export_vars -base "layout-del" { object_type page_url }]
    if { $default_p == "f" } {
	set default_url [export_vars -base "layout-default" { object_type page_url }]
    }
}


