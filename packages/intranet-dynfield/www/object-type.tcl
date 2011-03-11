ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-05
    @cvs-id $Id: object-type.tcl,v 1.10 2011/03/09 12:42:11 po34demo Exp $

} {
    {object_type:notnull}
    orderby:optional
    {show_interfaces_p "0"}
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

set title "Dynfield Attributes of $object_type_pretty_name"
set context [list [list "/intranet-dynfield/" "DynField"] [list "object-types" "Object Types"] $title]


db_1row object_type_info "
select
        pretty_name as object_type_pretty_name,
        table_name,
        id_column
from
        acs_object_types
where
        object_type = :object_type
"
set main_table_name $table_name
set main_id_column $id_column


# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

set dbi_interfaces ""
set dbi_inserts ""
set dbi_procs ""
set generate_interfaces 0

set show_hidde_link "<a href=\"?[export_vars -base {} -url -override {{show_interfaces_p 0}} {object_type orderby show_interfaces_p}]\"> [_ intranet-dynfield.Hide_interfaces]</a>"

db_multirow attributes attributes_query {} {
    if {[empty_string_p $table_name]} {
	set table_name $main_table_name
	set id_column $main_id_column
    } else {
	db_1row "get id_column" "select id_column 
			from acs_object_type_tables 
			where object_type = :object_type 
			and table_name = :table_name"
    }
}



# ******************************************************
# Layouts Multirow
# ******************************************************

set exists_p [db_string default_layout_exists "
	select	count(*)
	from	im_dynfield_layout_pages lp
	where	lp.object_type = :object_type
		and lp.page_url = 'default';
"]
if {!$exists_p} {
    db_dml insert_default_layout "
	insert into im_dynfield_layout_pages (
		page_url,
		object_type,
		layout_type,
		default_p
	) values (
		'default',
		:object_type,
		'table',
		't'
	)
    "
}

set layout_query "
	select	lp.*
	from	im_dynfield_layout_pages lp
	where	lp.object_type = :object_type
"
db_multirow layout layout_query $layout_query



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
    select page_url, layout_type, default_p
    from im_dynfield_layout_pages
    where object_type = :object_type
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


# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

set extension_tables_query "
	select	ott.*
	from	acs_object_type_tables ott
	where	ott.object_type = :object_type
"
db_multirow extension_tables extension_tables_query $extension_tables_query



ad_return_template
