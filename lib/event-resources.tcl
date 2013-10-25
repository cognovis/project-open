# /intranet-events/lib/event-resources.tcl
#
# Variables from calling procedure:
# 	event_id
#	return_url

# ******************************************************
# Default & Security
# ******************************************************

set current_user_id [ad_maybe_redirect_for_registration]
im_event_permissions $current_user_id $event_id view read write admin
if {!$read} { return }

set return_url [im_url_with_query]
set form_mode "display"


set conf_item_options [db_list_of_lists resources "
	select	ci.conf_item_name || ' (' || ci.conf_item_nr || ')',
		ci.conf_item_id
	from	im_conf_items ci
	where	conf_item_type_id in ([im_conf_item_type_laptop]) and
		conf_item_id not in (
			select	cci.conf_item_id
			from	im_conf_items cci,
				acs_rels cr
			where	cr.object_id_two = cci.conf_item_id and
				cr.object_id_one = :event_id
		)
	order by ci.conf_item_name
"]

# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

set name_l10n [lang::message::lookup "" intranet-core.Name Name]
set nr_l10n [lang::message::lookup "" intranet-core.Nr Nr]

list::create \
    -name resource_list \
    -multirow resource_list_multirow \
    -key resource_id \
    -orderby_name "resources_orderby" \
    -no_data "No resource associated yet" \
    -elements {
	conf_item_name { 
	    label "$name_l10n"
	    link_url_col resource_url
	}
	conf_item_nr { 
	    label "$nr_l10n"
	    link_url_col resource_url
	}
	resource_delete {
	    label ""
	    display_template {
		<a href="@resource_list_multirow.delete_url@" class="button">#acs-kernel.common_Delete#</a>
	    }
	}
    } \
    -orderby {
	orderby {orderby resource_name}
	resource_name {orderby conf_item_name}
	resource_nr {orderby conf_item_nr}
    } \
    -filters {
	form_mode {}
	event_id {}
    }


db_multirow -extend {resource_url delete_url} resource_list_multirow get_resources "
	select	*
	from	im_conf_items ci,
		acs_rels r
	where	r.object_id_two = ci.conf_item_id and
		r.object_id_one = :event_id
	[template::list::orderby_clause -name resource_list -orderby]
" {
    set delete_url [export_vars -base "/intranet-events/resource-del" {event_id conf_item_id return_url}]
    set resource_url [export_vars -base "/intranet-confdb/new" {conf_item_id {form_mode display} return_url}]
}
