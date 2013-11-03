# /intranet-events/lib/event-customers.tcl
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

set current_url [im_url_with_query]
set form_mode "display"

# ******************************************************
# Create the list of all attributes of the current type
# ******************************************************

list::create \
    -name customer_list \
    -multirow customer_list_multirow \
    -key company_id \
    -orderby_name "customers_orderby" \
    -no_data "No customer associated yet" \
    -elements {
	company_name { 
	    label "Name" 
	    link_url_col company_url
	}
	company_path { 
	    label "Path" 
	    link_url_col company_url
	}
	company_delete {
	    label ""
	    display_template {
		<a href="@customer_list_multirow.delete_url@" class="button">#acs-kernel.common_Delete#</a>
	    }
	}
    } \
    -orderby {
	orderby {orderby company_name}
	company_name {orderby company_name}
    } \
    -filters {
	form_mode {}
	event_id {}
    }


db_multirow -extend {company_url delete_url} customer_list_multirow get_customers "
	select	*
	from	im_companies c,
		acs_rels r
	where	r.object_id_two = c.company_id and
		r.object_id_one = :event_id
	[template::list::orderby_clause -name customer_list -orderby]
" {
    set delete_url [export_vars -base "customer-del" { event_id {customer_id $company_id} {return_url $current_url} }]
    set company_url [export_vars -base "/intranet/companies/view" { company_id {return_url $current_url} }]
}
