# /packages/intranet-trans-project-wizard/www/trans-project-wizard.tcl
#
# Copyright (c) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

if {![info exists project_id]} {
    ad_page_contract {
	Show the status and a description of a number of steps to 
	execute a translation project
	@author frank.bergmann@project-open.com
    } {
	project_id
    }
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

set table_width 500

set return_url [im_url_with_query]
set project_url "/intranet/projects/view"
set help_gif_url "/intranet/images/help.gif"
set progress_url "/intranet/images/progress_greygreen"

set status_display(0) "<img src=$progress_url.0.gif>"
set status_display(1) "<img src=$progress_url.1.gif>"
set status_display(2) "<img src=$progress_url.2.gif>"
set status_display(3) "<img src=$progress_url.3.gif>"
set status_display(4) "<img src=$progress_url.4.gif>"
set status_display(5) "<img src=$progress_url.5.gif>"
set status_display(6) "<img src=$progress_url.6.gif>"
set status_display(7) "<img src=$progress_url.7.gif>"
set status_display(8) "<img src=$progress_url.8.gif>"
set status_display(9) "<img src=$progress_url.9.gif>"
set status_display(10) "<img src=$progress_url.10.gif>"

set freelance_invoices_installed_p [util_memoize "db_string freelance_inv_exists \"select count(*) from apm_packages where package_key = 'intranet-freelance-invoices'\""]


# ---------------------------------------------------------------------
# Setup Multirow to store data
# ---------------------------------------------------------------------


multirow create call_to_quote status value url name description class
multirow create execution status value url name description class
multirow create invoicing status value url name description class

set multi_row_count 0

# ------------------------------------------------------------------------------------------------
# Call-To-Quote Worklfow
# ------------------------------------------------------------------------------------------------

set call_to_quote_header [lang::message::lookup "" intranet-trans-project-wizard.Call_to_Quote_header "From Call to Quote"]
set call_to_quote_description [lang::message::lookup "" intranet-trans-project-wizard.Call_to_Quote_Workflow_descr "
The 'Call to Quote' process leads you through the definition and setup of a new project 
after a customer has contacted you.
The average duration is 2.5 minutes plus TM analysis time.
"]

# ---------------------------------------------------------------------
# Project Base Data
# ---------------------------------------------------------------------

# Show status "done" = 10, as the base data must have been entered to get
# to this page...

set base_data_info [db_string base_data_info "
	select	project_nr
	from	im_projects
	where	project_id = :project_id
"]

incr multi_row_count
multirow append call_to_quote \
    $status_display(10) \
    $base_data_info \
    [export_vars -base "/intranet/projects/new" {project_id return_url}] \
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
    [export_vars -base "/intranet-translation/projects/edit-trans-data" {project_id return_url}] \
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
    "$trans_tasks [lang::message::lookup "" intranet-trans-project-wizard.Trans_Tasks "Task(s)"]" \
    [export_vars -base "/intranet-translation/trans-tasks/task-list?view_name=trans_tasks" {project_id return_url}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Trans_Tasks_name "Define Translation Tasks"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Trans_Tasks_descr "
	Setup the information about the file to be translated."] \
    $bgcolor([expr $multi_row_count % 2])



# ---------------------------------------------------------------------
# Quotes available?
# ---------------------------------------------------------------------

set quotes [db_string quotes "
        select  count(*)
        from    im_costs c
        where   c.cost_type_id = [im_cost_type_quote]
		and (
			c.project_id = :project_id
		    OR
			c.cost_id in (
				select	object_id_two
				from	acs_rels
				where	object_id_one = :project_id
			)
		)
"]
if {$quotes > 0} { set quotes_status 10} else { set quotes_status 0}

set quote_url "/intranet-trans-invoices/invoices/new?target_cost_type_id=3702"

incr multi_row_count
multirow append call_to_quote \
    $status_display($quotes_status) \
    "$quotes [lang::message::lookup "" intranet-trans-project-wizard.Quote_s_ "Quote(s)"]" \
    [export_vars -base $quote_url {project_id return_url}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Quotes_name "Write Quotes"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Quotes_descr "
	Create a quote by applying the customer's price list of the translation tasks."] \
    $bgcolor([expr $multi_row_count % 2])





# ---------------------------------------------------------------------
# Hours Logged?
# ---------------------------------------------------------------------

set first_invoice_date [db_string first_invoice "
	select	min(creation_date)
	from	(
			select	o.creation_date + '30 minutes'::interval as creation_date
			from	im_costs c,
				acs_objects o
			where	c.cost_id = o.object_id and
				c.project_id = :project_id and
				cost_type_id in ([im_cost_type_invoice], [im_cost_type_quote])
		    UNION
			select	now() as creation_date
		) t
"]

set hours1 [db_string hours1 "
        select  sum(h.hours)
        from    im_hours h
        where   h.project_id = :project_id and
		h.user_id = :user_id and
		h.day < :first_invoice_date
"]

if {"" == $hours1} { set hours1 0 }
if {$hours1 > 0} { set hours1_status 10} else { set hours1_status 0}

set hours1_url "/intranet-timesheet2/hours/new"

incr multi_row_count
multirow append call_to_quote \
    $status_display($hours1_status) \
    "$hours1 [lang::message::lookup "" intranet-trans-project-wizard.Hours "Hours(s)"]" \
    [export_vars -base $hours1_url {project_id return_url}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Hours1_name "Log Your Hours for Creating This Quote"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Hours1_descr "
	Please log your hours that you've spend to create the quote.
	This display only counts hours that you have logged until 30 minutes after creating
        your first quote for this project.
    "] \
    $bgcolor([expr $multi_row_count % 2])



# ------------------------------------------------------------------------------------------------
# Execution Workflow
# ------------------------------------------------------------------------------------------------

set execution_header [lang::message::lookup "" intranet-trans-project-wizard.Execution_header "From Quote to Deliverable"]
set execution_description [lang::message::lookup "" intranet-trans-project-wizard.Execution_Workflow_descr "
The 'Quote to Deliverable' process covers the staffing, assignation and execution of project tasks.
The execution itself is driven by translators down- and uploading translation files.
"]




# ---------------------------------------------------------------------
# All files uploaded?
# ---------------------------------------------------------------------

set file_upload_status 0
set missing_task_list {}
set upload_files_url ""
if {$trans_tasks > 0} {

    set missing_task_list [im_task_missing_file_list -no_complain 1 $project_id]
    set task_id [lindex $missing_task_list 0]
    set upload_files_url [export_vars -base "/intranet-translation/trans-tasks/upload-task" {project_id task_id return_url}]
    set file_upload_status [expr round(10.0 * ($trans_tasks - [llength $missing_task_list]) / $trans_tasks)]

}


incr multi_row_count
multirow append execution \
    $status_display($file_upload_status) \
    "[llength $missing_task_list] [lang::message::lookup "" intranet-trans-project-wizard.Missing_Files "Missing File(s)"]" \
    $upload_files_url \
    [lang::message::lookup "" intranet-trans-project-wizard.Upload_Missing_Files "Upload Missing File(s)"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Upload_Missing_Files_descr "
        Make sure all task files have been uploaded."] \
    $bgcolor([expr $multi_row_count % 2])


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
		r.object_id_one = :project_id
		and r.object_id_two = p.person_id
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
		r.object_id_one = :project_id
		and r.object_id_two = pe.person_id
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

set all_translators [expr $freelancers + $in_house_translators]
if {$all_translators > 0} { set freelancers_status 10} else { set freelancers_status 0}

set member_add_url "/intranet/member-add?object_id=$project_id&also_add_to_group_id=1"

incr multi_row_count
multirow append execution \
    $status_display($freelancers_status) \
    "$all_translators [lang::message::lookup "" intranet-trans-project-wizard.Translators "Translator(s)"]" \
    [export_vars -base $member_add_url {project_id return_url}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Freelancers_name "Select translators"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Freelancers_descr "
	Select a number of translators, editors and other resources to execute your project."] \
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

set assign_tasks_url "/intranet-translation/trans-tasks/task-assignments"

incr multi_row_count
multirow append execution \
    $status_display($assignations_status) \
    "$assigned_tasks [lang::message::lookup "" intranet-trans-project-wizard.Assigned_Tasks "Assigned Task(s)"]" \
    [export_vars -base $assign_tasks_url {project_id return_url}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Assignations_name "Assign Translators to Tasks"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Assignations_descr "
	Assign translators to the project tasks to determine who should do what."] \
    $bgcolor([expr $multi_row_count % 2])




# ---------------------------------------------------------------------
# Purchase_Orders written
# ---------------------------------------------------------------------

set purchase_orders 0
if {$freelance_invoices_installed_p} {

    set purchase_orders [db_string purchase_orders "
        select  count(*)
        from    im_costs
        where   project_id = :project_id
                and cost_type_id = [im_cost_type_po]
    "]

    if {$freelancers > 0} {
	set purchase_orders_status [expr 10 * $purchase_orders / $freelancers]
    } else {
	set purchase_orders_status 0
    }
    if {$purchase_orders_status > 10} { set purchase_orders_status 10 }
    
    set write_po_url "/intranet-freelance-invoices/index?target_cost_type_id=3706"
    
    incr multi_row_count
    multirow append execution \
	$status_display($purchase_orders_status) \
	"$purchase_orders [lang::message::lookup "" intranet-trans-project-wizard.POs "PO(s)"]" \
	[export_vars -base $write_po_url {project_id return_url}] \
	[lang::message::lookup "" intranet-trans-project-wizard.POs_name "Write Purchase Orders"] \
	[lang::message::lookup "" intranet-trans-project-wizard.POs_descr "
	Apply the translator's price list to project tasks to generate purchase orders."] \
	$bgcolor([expr $multi_row_count % 2])

}


# ---------------------------------------------------------------------
# Translation Workflow Completion
# ---------------------------------------------------------------------

set translation_advance [im_trans_task_project_advance $project_id]
if {"" == $translation_advance} { set translation_advance 0 }

set translation_advance [expr round($translation_advance)]
set translation_advance_status [expr round($translation_advance / 10)]

incr multi_row_count
multirow append execution \
    $status_display($translation_advance_status) \
    "$translation_advance [lang::message::lookup "" intranet-trans-project-wizard.Perc_Done "%%done"]" \
    [export_vars -base $project_url {project_id return_url}] \
    [lang::message::lookup "" intranet-trans-project-wizard.POs_name "Watch Translation Advance"] \
    [lang::message::lookup "" intranet-trans-project-wizard.POs_descr "
	Please see the \]po\[ workflow guide (check Google for 'PO-Translation-Workflow-Guide')."] \
    $bgcolor([expr $multi_row_count % 2])





# ------------------------------------------------------------------------------------------------
# Post-Delivery Workflow
# ------------------------------------------------------------------------------------------------

set invoicing_header [lang::message::lookup "" intranet-trans-project-wizard.Invoicing_header "From Deliverable to Cash"]
set invoicing_description [lang::message::lookup "" intranet-trans-project-wizard.Invoicing_Workflow_descr "
The invoicing workflow leads you 
"]



# ---------------------------------------------------------------------
# Provider Bills
# ---------------------------------------------------------------------

set bills [db_string bills "
        select  count(*)
        from    im_costs
        where   project_id = :project_id
                and cost_type_id = [im_cost_type_bill]
"]

if {0 != $purchase_orders} {
    set bills_status [expr round(10 * $bills / $purchase_orders)]
} else {
    set bills_status 0
}
if {$bills_status > 10} { set bills_status 10}

set bill_from_po_url "/intranet-invoices/new-copy-invoiceselect?source_cost_type_id=3706&target_cost_type_id=3704"

incr multi_row_count
multirow append invoicing \
    $status_display($bills_status) \
    "$bills [lang::message::lookup "" intranet-trans-project-wizard.Bills "Bills"]" \
    [export_vars -base $bill_from_po_url {project_id return_url}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Bills_name "Write Bill"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Bills_descr "
	Each Purchase Order should be folled by a 'Provider Bill' for the same provider."] \
    $bgcolor([expr $multi_row_count % 2])




# ---------------------------------------------------------------------
# Invoices
# ---------------------------------------------------------------------

set invoices [db_string invoices "
        select  count(*)
        from    im_costs
        where   cost_type_id = [im_cost_type_invoice]
		and (
			project_id = :project_id
		   OR
			cost_id in (
				select	object_id_two
				from	acs_rels
				where	object_id_one = :project_id
			)
		)

"]

if {0 != $quotes} {
    set invoices_status [expr round(10 * $invoices / $quotes)]
} else {
    set invoices_status 0
}
if {$invoices_status > 10} { set invoices_status 10}

set write_invoices_url "/intranet-invoices/new-copy-invoiceselect?source_cost_type_id=3702&target_cost_type_id=3700"

incr multi_row_count
multirow append invoicing \
    $status_display($invoices_status) \
    "$invoices [lang::message::lookup "" intranet-trans-project-wizard.Invoices "Invoices"]" \
    [export_vars -base $write_invoices_url {project_id return_url}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Invoices_name "Write Invoice"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Invoices_descr "
	Each Quote should be folled by an Invoice to the customer."] \
    $bgcolor([expr $multi_row_count % 2])



# ---------------------------------------------------------------------
# Bills Payment
# ---------------------------------------------------------------------

set paid_bills [db_string paid_bills "
        select  count(*)
        from    im_costs
        where   project_id = :project_id
                and cost_type_id = [im_cost_type_bill]
		and paid_amount > 0
"]

if {0 != $bills} {
    set paid_bills_status [expr round(10 * $paid_bills / $bills)]
} else {
    set paid_bills_status 0
}
if {$paid_bills_status > 10} { set paid_bills_status 10}

set pay_bills_url "/intranet-invoices/list?cost_type_id=3704"

incr multi_row_count
multirow append invoicing \
    $status_display($paid_bills_status) \
    "$paid_bills [lang::message::lookup "" intranet-trans-project-wizard.Paid_Bills "Paid Bills"]" \
    [export_vars -base $pay_bills_url {project_id return_url}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Paid_Bills_name "Pay Providers"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Paid_Bills_descr "
	Each Provider Bill should register a payment."] \
    $bgcolor([expr $multi_row_count % 2])


# ---------------------------------------------------------------------
# Invoices Payment
# ---------------------------------------------------------------------

set paid_invoices [db_string paid_invoices "
        select  count(*)
        from    im_costs
        where   project_id = :project_id
                and cost_type_id = [im_cost_type_invoice]
		and paid_amount > 0
"]

if {0 != $invoices} {
    set paid_invoices_status [expr round($paid_invoices / $invoices)]
} else {
    set paid_invoices_status 0
}
if {$paid_invoices_status > 10} { set paid_invoices_status 10}

set pay_invoices_url "/intranet-invoices/list?cost_type_id=3700"

incr multi_row_count
multirow append invoicing \
    $status_display($paid_invoices_status) \
    "$paid_invoices [lang::message::lookup "" intranet-trans-project-wizard.Paid_Invoices "Paid Invoices"]" \
    [export_vars -base $pay_invoices_url {project_id return_url}] \
    [lang::message::lookup "" intranet-trans-project-wizard.Paid_Invoices_name "Receive Payments"] \
    [lang::message::lookup "" intranet-trans-project-wizard.Paid_Invoices_descr "
	Each Invoice should register a payment."] \
    $bgcolor([expr $multi_row_count % 2])


