ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-01-04
    @cvs-id $Id: object-types.tcl,v 1.16 2010/11/15 20:10:54 po34demo Exp $

} {
    {orderby "name"}
}

# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set page_title "Object Types"
set context_bar [im_context_bar [list /intranet-dynfield/ "DynField"] $page_title]

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

# ------------------------------------------------------------------
# 
# ------------------------------------------------------------------

list::create \
    -name object_types \
    -multirow object_types \
    -key object_type \
    -row_pretty_plural "Object Types" \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions {
    } -bulk_actions {
    } -elements {
        edit {
            label {}
        }
        pretty_name {
            display_col pretty_name
            label "Pretty Name"
            link_url_eval $object_attributes_url
        }
        object_type {
            display_col object_type
            label "Object Type"
            link_url_eval $object_attributes_url
        }        
    } -filters {
    } -groupby {
    } -orderby {
    } -formats {
        normal {
            label "Table"
            layout table
            row {
                pretty_name {}
                object_type {}
            }
        }
    }


db_multirow -extend { object_attributes_url } object_types select_object_types {
	select	object_type,
    		pretty_name
	from	acs_object_types
	where	object_type in (
			'im_company', 'im_office', 'im_project', 'im_ticket', 'person', 
			'im_freelance_rfq', 'im_freelance_rfq_answer',
			'im_conf_item', 'im_cost_center', 'im_note', 'im_user_absence',
			'im_invoice', 'im_expense', 'im_expense_bundle',
			'im_material', 'im_timesheet_task',
			'im_sla_parameter'
		)
	order by
		lower(pretty_name)
} {
    set object_attributes_url "object-type?object_type=$object_type"
}


ad_return_template
