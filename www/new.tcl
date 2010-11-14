# /packages/intranet-sla-management/www/new.tcl
#
# Copyright (C) 2003-2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Show, create and edit a single SLA parameter
    @author frank.bergmann@project-open.com
} {
    param_id:integer,optional
    {param_sla_id:integer "" }
    {param_name "" }
    {return_url "/intranet-sla-management/index"}
    {form_mode "edit"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-sla-management.SLA_Parameter "SLA Parameter"]
if {[info exists param_id]} { set page_title [lang::message::lookup "" intranet-sla-management.SLA_parameter SLA_parameter] }
set context_bar [im_context_bar $page_title]

# We can determine the ID of the "container object" from the
# SLA parameter data, if the param_id is there (viewing an existing param).
if {[info exists param_id] && "" == $param_sla_id} {
    set param_sla_id [db_string oid "select param_sla_id from im_sla_parameters where param_id = :param_id" -default ""]
}


# ---------------------------------------------------------------
# Create the Form
# ---------------------------------------------------------------

set form_id "form"
ad_form \
    -name $form_id \
    -mode $form_mode \
    -export "param_sla_id return_url" \
    -form {
	param_id:key
	{param_name:text(text) {label "[lang::message::lookup {} intranet-sla-management.SLA_Parameter_Name Name]"}}
	{param_type_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-sla-management.SLA_Parameter_Type Type]"} {custom {category_type "Intranet SLA Parameter Type" translate_p 1 package_key intranet-sla-management include_empty_p 0}} }
	{param_note:text(textarea),optional {label "[lang::message::lookup {} intranet-sla-management.SLA_Parameter_Note Note]"} {html {cols 40} {rows 8}} }
    }


# Add DynFields to the form
set my_param_id 0
if {[info exists param_id]} { set my_param_id $param_id }
im_dynfield::append_attributes_to_form \
    -object_type "im_sla_parameter" \
    -form_id $form_id \
    -object_id $my_param_id



# ---------------------------------------------------------------
# Define Form Actions
# ---------------------------------------------------------------

ad_form -extend -name $form_id \
    -select_query {

	select	*
	from	im_sla_parameters
	where	param_id = :param_id

    } -new_data {

        set param_note [string trim $param_note]
        set duplicate_param_sql "
                select  count(*)
                from    im_sla_parameters
                where   param_sla_id = :param_sla_id and param_name = :param_name
        "
        if {[db_string dup $duplicate_param_sql]} {
            ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-sla-management.Duplicate_parameter "Duplicate parameter"]</b>:<br>
            [lang::message::lookup "" intranet-sla-management.Duplicate_parameter_msg "
	    	There is already a parameter with the same name for the same SLA.
	    "]"
	    ad_script_abort
        }

	set param_id [db_exec_plsql create_note "
		SELECT im_sla_parameter__new(
			:param_id,
			'im_sla_parameter',
			now(),
			:user_id,
			'[ad_conn peeraddr]',
			null,

			:param_name,
			:param_sla_id,
			:param_type_id,
			[im_sla_parameter_status_active],
			:param_note
		)
        "]

        im_dynfield::attribute_store \
            -object_type "im_sla_parameter" \
            -object_id $param_id \
            -form_id $form_id

    } -edit_data {

        set note [string trim $note]
	db_dml edit_note "
		update im_sla_parameters set 
			param_name = :param_name,
			param_sla_id = :param_sla_id,
			param_type_id = :param_type,
			param_note = :param_notenote
		where param_id = :param_id
	"
        im_dynfield::attribute_store \
            -object_type "im_sla_parameter" \
            -object_id $param_id \
            -form_id $form_id

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }

