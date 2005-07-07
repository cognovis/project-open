# /packages/intranet-reporting/www/new-variable.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Create a new view or edit an existing one.

    @param form_mode edit or display

    @author juanjoruizx@yahoo.es
} {
	report_id:notnull
    variable_id:integer,optional
    return_url
    edit_p:optional
    message:optional
    { form_mode "display" }
}


# ------------------------------------------------------------------
# Default & Security
# ------------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

set action_url ""
set focus "variable.variable_name"
set page_title "[_ intranet-reporting.New_variable]"
set context $page_title

if {![info exists variable_id]} { set form_mode "edit" }


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

#set widget_options [db_list_of_lists select_widgets {
#        select
#                fw.widget_name,
#                fw.widget_name
#        from
#                im_dynfield_widgets fw
#        order by
#                fw.widget_name
#} ]

set widget_options { {1 1} {2 2} {3 3} }
set widget_options [linsert $widget_options 0 {" " ""}]

ad_form \
    -name variable \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {user_id report_id return_url} \
    -form {
		variable_id:key(im_report_variables_seq)
		{variable_name:text(text) {label #intranet-reporting.Variable_Name#}  {html {size 15 maxlength 100}} }
		{pretty_name:text(text),optional {label #intranet-reporting.Pretty_Name#}  {html {size 20 maxlength 100}} }
		{widget_name:text(select),optional {label #intranet-reporting.Widget_Name#}  {options $widget_options} }
    }


ad_form -extend -name variable -on_request {
    # Populate elements from local variables
    

} -select_query {

	select	rv.variable_id,
			rv.variable_name,
			rv.pretty_name,
			rv.widget_name
	from	IM_REPORT_VARIABLES rv
	where	rv.variable_id = :variable_id
	and		rv.report_id = :report_id

} -validate {

        {variable_name
            {![db_string unique_name_check "select count(*) from im_report_variables \
                                            where variable_name = :variable_name \
                                            and report_id = :report_id \
                                            and variable_id != :variable_id"]}
            "Duplicate variable Name. Please use a new name."
        }

} -new_data {

    db_dml variable_insert "
    insert into IM_REPORT_VARIABLES
    (variable_id, report_id, variable_name, widget_name, pretty_name)
    values
    (:variable_id, :report_id, :variable_name, :widget_name, :pretty_name)
    "

} -edit_data {

    db_dml variable_update "
	update IM_VIEW_COLUMNS set
	        variable_name    = :variable_name,
	        pretty_name  = :pretty_name,
	        widget_name    = :widget_name
	where
		variable_id = :variable_id
		and report_id = :report_id
"
} -on_submit {

	ns_log Notice "new1: on_submit"


} -after_submit {

	ad_returnredirect $return_url
	ad_script_abort
}


#      (select population_id, area_id, sum(gdp) from country_fact group by population_id, area_id)
#union (select population_id, null,    sum(gdp) from country_fact group by population_id);
