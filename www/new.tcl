# /packages/intranet-baseline/www/new.tcl
#
# Copyright (C) 2003-2010 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Create a new baseline and edit existing baselines
    @author frank.bergmann@project-open.com
} {
    baseline_id:integer,optional
    {baseline_project_id:integer ""}
    {baseline ""}
    {return_url "/intranet-baseline/index"}
    {form_mode "edit"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title [lang::message::lookup "" intranet-baseline.New_Baseline "New Baseline"]
if {[info exists baseline_id]} { 
    set baseline_name ""
    set baseline_project_id 0
    db_0or1row baseline_info "
	select	*
	from	im_baselines
	where	baseline_id = :baseline_id
    "
    if {"" != $baseline_name} {
	set page_title [lang::message::lookup "" intranet-baseline.Baseline "Baseline %baseline_name%"] 
    }

    im_project_permissions $current_user_id $baseline_project_id view read write admin
    if {!$read} { 
	ad_return_complaint 1 "You don't have the permissions to see this baseline"
	ad_script_abort
    }

}
set context_bar [im_context_bar $page_title]

# We can determine the ID of the "container object" from the
# baseline data, if the baseline_id is there (viewing an existing baseline).
if {[info exists baseline_id] && "" == $baseline_project_id} {
    set baseline_project_id [db_string oid "select baseline_project_id from im_baselines where baseline_id = :baseline_id" -default ""]
}

# Show the ADP component plugins?
set show_components_p 1
if {"edit" == $form_mode} { set show_components_p 0 }


# ---------------------------------------------------------------
# Create the Form
# ---------------------------------------------------------------

set form_id "form"
ad_form \
    -name $form_id \
    -mode $form_mode \
    -export "baseline_project_id return_url" \
    -form {
	baseline_id:key
	{baseline_name:text(text) {label "[lang::message::lookup {} intranet-baseline.Baseline_Name {Baseline Name}]"} {html {size 40}}}
	{baseline_status_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-baseline.Baseline_Status {Baseline Status}]"} \
		{custom {category_type "Intranet Baseline Status" translate_p 1 package_key intranet-baseline include_empty_p 0}} }
	{baseline_type_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-baseline.Baseline_Type {Baseline Type}]"} \
		{custom {category_type "Intranet Baseline Type" translate_p 1 package_key intranet-baseline include_empty_p 0}} }
    }

# Add DynFields to the form
set my_baseline_id 0
if {[info exists baseline_id]} { set my_baseline_id $baseline_id }
im_dynfield::append_attributes_to_form \
    -object_type "im_baseline" \
    -form_id $form_id \
    -object_id $my_baseline_id



# ---------------------------------------------------------------
# Define Form Actions
# ---------------------------------------------------------------

ad_form -extend -name $form_id \
    -select_query {
	select	*
	from	im_baselines
	where	baseline_id = :baseline_id

    } -new_data {

	# Check permissions
	im_project_permissions $current_user_id $baseline_project_id view read write admin
	set add_baselines_p [im_permission $current_user_id "add_baselines"]
	if {!$admin || !$add_baselines_p} { 
	    ad_return_complaint 1 "You need to be a project manager and to have add_baselines permissions in order to create a add or modify baselines".
	    ad_script_abort
	}

        set baseline [string trim $baseline]
        set duplicate_baseline_sql "
                select	count(*)
                from	im_baselines
                where	baseline_project_id = :baseline_project_id and 
			baseline_name = :baseline_name
        "
        if {[db_string dup $duplicate_baseline_sql]} {
            ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-baseline.Duplicate_baseline "Duplicate baseline"]</b>:<br>
            [lang::message::lookup "" intranet-baseline.Duplicate_baseline_msg "
	    	There is already the same baseline available for the specified object.
	    "]"
	    ad_script_abort
        }

	set baseline_id [db_exec_plsql create_baseline "
		SELECT im_baseline__new(
			:baseline_id,
			'im_baseline',
			now(),
			:current_user_id,
			'[ad_conn peeraddr]',
			null,
			:baseline_name,
			:baseline_project_id,
			:baseline_type_id,
			:baseline_status_id
		)
        "]

        im_dynfield::attribute_store \
            -object_type "im_baseline" \
            -object_id $baseline_id \
            -form_id $form_id

	# Create a version of the current project tree
	set project_tree_sql "
		select	child.project_id as child_project_id
		from	im_projects child,
			im_projects parent
		where	parent.project_id = :baseline_project_id and
			child.tree_sortkey between parent.tree_sortkey and tree_right(parent.tree_sortkey)
	"
	db_foreach project_tree $project_tree_sql {
	    im_project_audit_impl -project_id $child_project_id -baseline_id $baseline_id -action "baseline"
	}

    } -edit_data {

	# Check permissions
	im_project_permissions $current_user_id $baseline_project_id view read write admin
	set add_baselines_p [im_permission $current_user_id "add_baselines"]
	if {!$admin || !$add_baselines_p} { 
	    ad_return_complaint 1 "You need to be a project manager and to have add_baselines permissions in order to create a add or modify baselines".
	    ad_script_abort
	}

        set baseline [string trim $baseline]
	db_dml edit_baseline "
		update im_baselines set 
			baseline_name = :baseline_name,
			baseline_project_id = :baseline_project_id,
			baseline_status_id = :baseline_status_id,
			baseline_type_id = :baseline_type_id
		where baseline_id = :baseline_id
	"
        im_dynfield::attribute_store \
            -object_type "im_baseline" \
            -object_id $baseline_id \
            -form_id $form_id

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }


set sub_navbar ""
set left_navbar_html ""

