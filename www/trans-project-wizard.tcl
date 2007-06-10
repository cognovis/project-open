# /packages/intranet-trans-project-wizard/www/trans-project-wizard.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Show the status and a description of a number of steps to 
    execute a translation project

    @author frank.bergmann@project-open.com

} {
    project_id
}


# ---------------------------------------------------------------------
# Permissions & Defaults
# ---------------------------------------------------------------------

if {![info exists project_id]} {
    ad_return_complaint 1 "Trans-Project-Wizard: No project_id specified"
}

set user_id [ad_maybe_redirect_for_registration]
im_project_permissions $user_id $project_id view read write admin
if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    ad_script_abort
}

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"
set multi_row_count 0

set project_url "/intranet/projects/view"
set help_gif_url "/intranet/images/help.gif"

set status_display(todo) "0"
set status_display(done) "10"

set status_display(0) "0"
set status_display(1) "1"
set status_display(2) "2"
set status_display(3) "3"
set status_display(4) "4"
set status_display(5) "5"
set status_display(6) "6"
set status_display(7) "7"
set status_display(8) "8"
set status_display(9) "9"
set status_display(10) "10"


# ---------------------------------------------------------------------
# Setup Multirow to store data
# ---------------------------------------------------------------------


multirow create call_to_quote status value url name description class
multirow create execution status value url name description class
multirow create invoicing status value url name description class




# ------------------------------------------------------------------------------------------------
# Call-To-Quote Worklfow
# ------------------------------------------------------------------------------------------------

set call_to_quote_description [lang::message::lookup "" intranet-trans-project-wizard.Call_to_Quote_Workflow_descr "
The quoting workflow leads you from the definition of a new project to the creation
of a quote. 
The average time for performing this workflow is 2''40 (two minutes and 40 seconds)
plus TM analysis time, according to benchmarks with several customers.
"]
set ttt "The workflow is triggered by a customer's request, such as an email with some files to translate."

# ---------------------------------------------------------------------
# Project Base Data
# ---------------------------------------------------------------------

# Show status "done", as the base data must have been entered to get
# to this page...

incr multi_row_count
multirow append call_to_quote \
    $status_display(done) \
    "" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Define_Project_Base_Data_name "Define Project Base Data"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Project_Base_Data_descr "
	Base data include project name, project number, start and end date."] \
    $bgcolor([expr $multi_row_count % 2])


# ---------------------------------------------------------------------
# Source + Target Language
# ---------------------------------------------------------------------

set source_language [db_string source_language_status "
	select	im_category_from_id(source_language_id)
	from	im_projects
	where	project_id = :project_id
"]
if {"" == $source_language} { set source_language_status 0 } else { set source_language_status 10 }
if {0 == $source_language} { set source_language "-" }


set target_languages [db_list target_language_status "
	select	im_category_from_id(language_id)
	from	im_target_languages
	where	project_id = :project_id
"]
if {[llength $target_languages] > 0} { set target_language_status 10 } else { set target_language_status 0 }
if {0 == $target_languages} { set target_languages "-" }

set status [expr round(0.5*$source_language_status + 0.5*$target_language_status)]

incr multi_row_count
multirow append call_to_quote \
    $status_display($status) \
    "$source_language -&gt; [join $target_languages ", "]" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Define_Source_and_Target_Language_name "Define Source and Target Languages"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Source_and_Target_Language_descr "
	You have to set the source and target languages of the project."] \
    $bgcolor([expr $multi_row_count % 2])



# ---------------------------------------------------------------------
# Translation Tasks
# ---------------------------------------------------------------------

set trans_tasks [db_string trans_tasks_status "
        select  count(*)
        from    im_trans_tasks
        where   project_id = :project_id
"]
if {$trans_tasks > 0} { set trans_tasks_status 10} else { set trans_tasks_status 0}


incr multi_row_count
multirow append call_to_quote \
    $status_display($trans_tasks_status) \
    "$trans_tasks [lang::message::lookup "" intranet-trans-project-wizard.Trans_Tasks "Tasks"]" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Trans_Tasks_name "Define Translation Tasks"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Trans_Tasks_descr "
	Setup the information about the file to be translated."] \
    $bgcolor([expr $multi_row_count % 2])



# ---------------------------------------------------------------------
# Quotes available?
# ---------------------------------------------------------------------

set quotes [db_string quotes "
        select  count(*)
        from    im_costs
        where   project_id = :project_id
		and cost_type_id = [im_cost_type_quote]
"]
if {$quotes > 0} { set quotes_status 10} else { set quotes_status 0}


incr multi_row_count
multirow append call_to_quote \
    $status_display($quotes_status) \
    "$quotes [lang::message::lookup "" intranet-trans-project-wizard.Quotes "Quotes"]" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Quotes_name "Write Quote"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Quotes_descr "
	Create a quote by applying the customer's price list of the translation tasks."] \
    $bgcolor([expr $multi_row_count % 2])







# ------------------------------------------------------------------------------------------------
# Execution Workflow
# ------------------------------------------------------------------------------------------------

set execution_description [lang::message::lookup "" intranet-trans-project-wizard.Execution_Workflow_descr "
The execution workflow leads you from the confirmation of your quote to the finished deliveries.
"]


# ---------------------------------------------------------------------
# Freelancers defined?
# ---------------------------------------------------------------------

# Check for freelancers or Employees with skill information set
set freelancers [db_string freelancers "
        select  count(*)
        from
		persons p,
		acs_rels r,
		group_distinct_member_map m
        where
		r.object_id_two = :project_id
		and r.object_id_one = p.person_id
		and p.person_id = m.member_id
		and m.group_id = [im_freelance_group_id]

"]

# In-house translators are employees that have been assigned atleast once to
# a translation task.
set in_house_translators [db_string in_house_translators "
        select  count(*)
        from
		persons pe,
		acs_rels r,
		group_distinct_member_map m
        where
		r.object_id_two = :project_id
		and r.object_id_one = pe.person_id
		and pe.person_id = m.member_id
		and m.group_id = [im_employee_group_id]
		and pe.person_id in (
			select	distinct trans_id
			from	im_trans_tasks
		    UNION
			select	distinct edit_id
			from	im_trans_tasks
		    UNION
			select	distinct proof_id
			from	im_trans_tasks
		    UNION
			select	distinct other_id
			from	im_trans_tasks
		)
"]

set freelancers [expr $freelancers + $in_house_translators]
if {$freelancers > 0} { set freelancers_status 10} else { set freelancers_status 0}

incr multi_row_count
multirow append execution \
    $status_display($freelancers_status) \
    "$freelancers [lang::message::lookup "" intranet-trans-project-wizard.Translators "Translators"]" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Freelancers_name "Select translators"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Freelancers_descr "
	Select a number of translators, editors and other resources to execute your project"] \
    $bgcolor([expr $multi_row_count % 2])




# ---------------------------------------------------------------------
# Assignations
# ---------------------------------------------------------------------

set assigned_tasks [db_string assigned_tasks "
        select  count(*)
        from    im_trans_tasks
        where   (trans_id is not NULL or
		 edit_id is not NULL or
		 proof_id is not NULL or
		 other_id is not NULL
		)
		and project_id = :project_id
"]
if {0 != $trans_tasks} {
    set assignations_status [expr 10 * $assigned_tasks / $trans_tasks]
} else {
    set assignations_status 0
}
if {$assignations_status > 10} { set assignations_status 10 }


incr multi_row_count
multirow append execution \
    $status_display($assignations_status) \
    "$assigned_tasks [lang::message::lookup "" intranet-trans-project-wizard.Assigned_Tasks "Assigned Tasks"]" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Assignations_name "Assign Translators to Tasks"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Assignations_descr "
	Assign translators to the project tasks to determine who should do what."] \
    $bgcolor([expr $multi_row_count % 2])





# ---------------------------------------------------------------------
# POs written
# ---------------------------------------------------------------------

set pos [db_string pos "
        select  count(*)
        from    im_costs
        where   project_id = :project_id
                and cost_type_id = [im_cost_type_po]
"]

if {$freelancers > 0} {
    set pos_status [expr 10 * $pos / $freelancers]
} else {
    set pos_status 0
}
if {$pos_status > 10} { set pos_status 10 }

incr multi_row_count
multirow append execution \
    $status_display($pos_status) \
    "$pos [lang::message::lookup "" intranet-trans-project-wizard.POs "POs"]" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.POs_name "Write Purchase Orders"] \
    [lang::message::lookup "" intranet-trans-project-wizard.POs_descr "
	Apply the translator's price list to the project's translation tasks to generate
	purchase orders."] \
    $bgcolor([expr $multi_row_count % 2])




# ------------------------------------------------------------------------------------------------
# Post-Delivery Workflow
# ------------------------------------------------------------------------------------------------

set invoicing_description [lang::message::lookup "" intranet-trans-project-wizard.Invoicing_Workflow_descr "
The invoicing workflow leads you 
"]


