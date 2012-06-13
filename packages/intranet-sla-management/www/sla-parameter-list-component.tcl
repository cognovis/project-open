# -------------------------------------------------------------
# /packages/intranet-sla-management/www/sla-parameters-list-component.tcl
#
# Copyright (c) 2011 ]project-open[
# All rights reserved.
#
# Author: frank.bergmann@project-open.com
#

# -------------------------------------------------------------
# Variables:
#	object_id:integer
#	return_url

if {![info exists object_id]} {
    ad_page_contract {
	@author frank.bergmann@project-open.com
    } {
	object_id:integer
    }
}

# This portlet only makes sense in SLAs...

if {![info exists return_url] || "" == $return_url} { set return_url [im_url_with_query] }
set current_user_id [ad_maybe_redirect_for_registration]
set new_sla_parameter_url [export_vars -base "/intranet-sla-management/new" {object_id return_url}]

# Check the permissions
# Permissions for all usual projects, companies etc.
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$current_user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd


# ----------------------------------------------------
# Create the list definition for SLA parameters.
# Start with the default fields that exist by default

set elements {
	rfq_chk {
	    label "<input type=\"checkbox\" name=\"_dummy\" \
		  onclick=\"acs_ListCheckAll('param_list', this.checked)\" \
		  title=\"Check/uncheck all rows\">"
	    display_template {
		@param_lines.param_chk;noquote@
	    }
	}
	param_name {	
	    label "[lang::message::lookup {} intranet-sla-management.SLA_Parameter_Type {Name}]"
	    link_url_col param_url
	}
	ticket_type {	
	    label "[lang::message::lookup {} intranet-sla-management.Ticket_Type {Ticket Type}]"
	}
	max_resolution_hours {	
	    label "[lang::message::lookup {} intranet-sla-management.Max_Resolution_Hours {Res. Time}]"
	}
}



# Add the DynFields from im_freelance_rfq_answers
set extra_selects [list "0 as zero"]
set column_sql "
        select  w.deref_plpgsql_function,
                aa.attribute_name,
		aa.pretty_name
        from    im_dynfield_widgets w,
                im_dynfield_attributes a,
                acs_attributes aa
        where   a.widget_name = w.widget_name and
                a.acs_attribute_id = aa.attribute_id and
                aa.object_type = 'im_sla_parameter'
"
db_foreach column_list_sql $column_sql {

    # Select another field
    lappend extra_selects "${deref_plpgsql_function}($attribute_name) as ${attribute_name}_deref"

    # Show this field in the template::list
    lappend elements ${attribute_name}_deref
    lappend elements { label "[lang::message::lookup {} intranet-freelance-rfqs.$attribute_name $pretty_name]" }

}
set extra_select [join $extra_selects ",\n\t"]


# -------------------------------------------------------------
# Define the list view

set actions_list [list]
set bulk_actions_list [list]

if {$object_write} {
    set new_msg [lang::message::lookup "" intranet-sla-management.New_Parameter "New Param"]
    lappend actions_list $new_msg [export_vars -base "/intranet-sla-management/new" {return_url {param_sla_id $object_id}}] $new_msg

    set delete_msg [lang::message::lookup "" intranet-sla-management.Delete_Parameter "Delete Param"]
    lappend bulk_actions_list $delete_msg "del-param" $delete_msg
}

set export_var_list [list object_id return_url]
set list_id "param_list"

template::list::create \
    -name $list_id \
    -multirow param_lines \
    -key param_id \
    -has_checkboxes \
    -actions $actions_list \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	object_id
	return_url
    } \
    -bulk_action_method POST \
    -row_pretty_plural "[lang::message::lookup {} intranet-sla-management.SLA_Parameters {SLA parameters}]" \
    -elements $elements

# ----------------------------------------------------
# Create a "multirow" to show the results
#
set extend_list {param_chk param_url}

set params_sql "
	select	sp.*,
		im_category_from_id(ticket_type_id) as ticket_type,
		$extra_select
	from	im_sla_parameters sp
	where	sp.param_sla_id = :object_id
	order by sp.param_id
"

db_multirow -extend $extend_list param_lines params $params_sql {
    set param_chk "<input type=checkbox name=param_ids value=$param_id id='param_list,$param_id'>"
    set param_url [export_vars -base "/intranet-sla-management/new" {{form_mode display} param_id}]
}

