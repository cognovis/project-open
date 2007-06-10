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
set rowcount 0

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


# ---------------------------------------------------------------------
# Project Base Data
# ---------------------------------------------------------------------

# Show status "done", as the base data must have been entered to get
# to this page...

incr rowcount
multirow append call_to_quote \
    $status_display(done) \
    "" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Project_Base_Data_name "Project Base Data"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Project_Base_Data_descr "
	Base data include project name, project number, start and end date.
    "] \
    $bgcolor([expr $rowcount % 2])


# ---------------------------------------------------------------------
# Source + Target Language
# ---------------------------------------------------------------------

set source_language [db_string source_language_status "
	select	im_category_from_id(source_language_id)
	from	im_projects
	where	project_id = :project_id
"]
if {"" == $source_language} { set source_language_status 0 } else { set source_language_status 10 }

set target_languages [db_list target_language_status "
	select	im_category_from_id(language_id)
	from	im_target_languages
	where	project_id = :project_id
"]

if {[llength $target_languages] > 0} { set target_language_status 10 } else { set target_language_status 0 }

set status [expr round(0.5*$source_language_status + 0.5*$target_language_status)]

incr rowcount
multirow append call_to_quote \
    $status_display($status) \
    "$source_language -&gt; [join $target_languages ", "]" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Source_and_Target_Language_name "Source and Target Languages"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Source_and_Target_Language_descr "
	You have to set the source and target languages of the project.
    "] \
    $bgcolor([expr $rowcount % 2])



# ---------------------------------------------------------------------
# Translation Tasks
# ---------------------------------------------------------------------

set trans_tasks [db_string trans_tasks_status "
        select  count(*)
        from    im_trans_tasks
        where   project_id = :project_id
"]
if {$trans_tasks > 0} { set trans_tasks_status 10} else { set trans_tasks_status 0}


incr rowcount
multirow append call_to_quote \
    $status_display($trans_tasks_status) \
    "$trans_tasks [lang::message::lookup "" intranet-trans-project-wizard.Trans_Tasks "Tasks"]" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Trans_Tasks_name "Define Translation Tasks"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Trans_Tasks_descr "
	Setup the information about the file to be translated.
    "] \
    $bgcolor([expr $rowcount % 2])



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


incr rowcount
multirow append call_to_quote \
    $status_display($quotes_status) \
    "$quotes [lang::message::lookup "" intranet-trans-project-wizard.Quotes "Quotes"]" \
    [export_vars -base $project_url {project_id}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Quotes_name "Write Quote"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Quotes_descr "
	Create a quote by applying the customer's price list of the translation tasks.
    "] \
    $bgcolor([expr $rowcount % 2])




# ---------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

# ---------------------------------------------------------------------
# 
# ---------------------------------------------------------------------

