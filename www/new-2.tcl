# /packages/intranet-trans-invoices/www/new-3.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    Receives the list of tasks to invoice and creates an invoice form
    similar to /intranet-invoicing/www/new in order to create a new
    invoice.<br>
    @author frank.bergmann@project-open.com
} {
    trans:array,optional
    edit:array,optional
    proof:array,optional
    other:array,optional
    provider_id:integer
    freelance_id:integer
    target_cost_type_id:integer
    { target_cost_status_id:integer 0 }
    { currency "EUR" }
    { return_url "/intranet-cost/index"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

if {0 == $target_cost_status_id} { set target_cost_status_id [im_cost_status_created] }
set cost_status_id $target_cost_status_id

set todays_date [db_string get_today "select to_char(sysdate,'YYYY-MM-DD') from dual"]
set page_focus "im_header_form.keywords"
set view_name "invoice_tasks"

set bgcolor(0) " class=roweven"
set bgcolor(1) " class=rowodd"

set number_format "9999990.099"

# ---------------------------------------------------------------
# Compute the t.task_id in (...) lists for trans, edit, proof and other
# ---------------------------------------------------------------

set trans_list [list]
lappend trans_list 0
set edit_list [list]
lappend edit_list 0
set proof_list [list]
lappend proof_list 0
set other_list [list]
lappend other_list 0

foreach task [array names trans] { lappend trans_list $task }
set trans_where_clause "and tt.task_id in ([join $trans_list ","])"

foreach task [array names edit] { lappend edit_list $task }
set edit_where_clause "and tt.task_id in ([join $edit_list ","])"

foreach task [array names proof] { lappend proof_list $task }
set proof_where_clause "and tt.task_id in ([join $proof_list ","])"

foreach task [array names other] { lappend other_list $task }
set other_where_clause "and tt.task_id in ([join $other_list ","])"



# ---------------------------------------------------------------
# Gather invoice data
# ---------------------------------------------------------------

set task_ids [array names task]

# Build the list of selected tasks ready for invoicing
set invoice_mode "new"


# Create the default values for a new purchase order
#
set button_text "[_ intranet-trans-invoices.lt_Create_Purchase_Order]"
set page_title "[_ intranet-trans-invoices.New_Purchase_Order]"
set context_bar [im_context_bar [list /intranet/invoices/ "[_ intranet-trans-invoices.Purchase_Orders]"] $page_title]
set invoice_id [im_new_object_id]
set invoice_nr [im_next_invoice_nr]
set invoice_date $todays_date
set payment_days [ad_parameter -package_id [im_package_cost_id] "DefaultProviderBillPaymentDays" "" 30] 
set vat 0
set tax 0
set note ""
set payment_method_id ""
set template_id ""


# ---------------------------------------------------------------
# Gather company data from the provider company_id
# ---------------------------------------------------------------

db_1row invoices_info_query "
select 
	c.*,
        o.*,
	im_email_from_user_id(c.accounting_contact_id) as company_contact_email,
	im_name_from_user_id(c.accounting_contact_id) as  company_contact_name,
	c.company_name as company_name,
	c.company_path as company_path,
	c.company_path as company_short_name,
        cc.country_name
from
	im_companies c, 
        im_offices o,
        country_codes cc
where 
        c.company_id = :provider_id
        and c.main_office_id=o.office_id(+)
        and o.address_country_code=cc.iso(+)
"


# ---------------------------------------------------------------
# Select and process the trans, edit, proof and other services
# for the selected files.
# The result is "provider_tasks_sql", a SQL query fragment that
# returns all the tasks that need to be purchased from the given
# freelancer.
# ---------------------------------------------------------------

# Get the freelancers Trados Matrix
#
array set provider_matrix [im_trans_trados_matrix $provider_id]

# How many words does a translator edit per hour?
set editing_words_per_hour 1000

# Select out the sum of units from the provider translation
# jobs.
# Provider translation wordcount is determined by multiplying
# the original Trados wordcount with the _providers_ trados
# matrix.
#
set trans_tasks_inner_sql "
	-- Select the wordcount 
	select  tt.*,
		'File translation: Trados wordcount multiplied with provider Trados matrix' as po_comment,
		[im_project_type_trans] as po_task_type_id,
		(	tt.match_x * $provider_matrix(x) +
			tt.match_rep * $provider_matrix(rep) +
			tt.match100 * $provider_matrix(100) +
			tt.match95 * $provider_matrix(95) +
			tt.match85 * $provider_matrix(85) +
			tt.match75 * $provider_matrix(75) +
			tt.match50 * $provider_matrix(50) +
			tt.match0 * $provider_matrix(0) 
		) as po_billable_units,
		tt.task_uom_id as po_task_uom_id
	from	im_trans_tasks tt
	where	tt.trans_id = :freelance_id
		and (
			tt.task_uom_id = [im_uom_s_word]
			and tt.match100 is not null
		)
		$trans_where_clause
UNION
	select  tt.*,
		'Translation of a manually added task: Just taking the manually specified task units' as po_comment,
		[im_project_type_trans] as po_task_type_id,
		tt.task_units as po_billable_units,
		tt.task_uom_id as po_task_uom_id
	from	im_trans_tasks tt
	where	tt.trans_id = :freelance_id
		and (
			tt.task_uom_id != [im_uom_s_word]
			or tt.match100 is null
		)
		$trans_where_clause
"

# Select out the tasks from editing the files.
# Edit time is normally calculated as brut word count
# (no trados matrix applied) diveded by 1000 words/hour.
#
# However, this only applies to "files" as translation
# tasks. There may be already some editing tasks specified
# by hour.
set edit_tasks_inner_sql "
	select  tt.*,
		'File editing: Converting the total wordcount into editing hours using $editing_words_per_hour words per hour' as po_comment,
		[im_project_type_edit] as po_task_type_id,
		(	tt.match_x +
			tt.match_rep +
			tt.match100 +
			tt.match95 +
			tt.match85 +
			tt.match75 +
			tt.match50 +
			tt.match0
		) / $editing_words_per_hour as po_billable_units,
		[im_uom_hour] as po_task_uom_id
	from	im_trans_tasks tt
	where	tt.edit_id = :freelance_id
		and (
			tt.task_uom_id = [im_uom_s_word]
			and tt.match100 is not null
		)
		$edit_where_clause
UNION
	select  tt.*,
		'Editing a manually added task: Just taking the manually specified task units' as po_comment,
		[im_project_type_edit] as po_task_type_id,
		tt.task_units as po_billable_units,
		tt.task_uom_id as po_task_uom_id
	from	im_trans_tasks tt
	where	tt.edit_id = :freelance_id
		and (
			tt.task_uom_id != [im_uom_s_word]
			or tt.match100 is null
		)
		$edit_where_clause
"

set provider_tasks_sql "
		$trans_tasks_inner_sql
        UNION
		$edit_tasks_inner_sql
        UNION
                select  tt.*,
			'' as po_comment,
                        [im_project_type_proof] as po_task_type_id,
                        tt.billable_units as po_billable_units,
                        tt.task_uom_id as po_task_uom_id
                from    im_trans_tasks tt
                where   tt.proof_id = :freelance_id
                        $proof_where_clause
        UNION
                select  tt.*,
			'' as po_comment,
                        [im_project_type_other] as po_task_type_id,
                        tt.billable_units as po_billable_units,
                        tt.task_uom_id as po_task_uom_id
                from    im_trans_tasks tt
                where   tt.other_id = :freelance_id
                        $other_where_clause
"

# for testing purposes: replace complex query by simple query...
set xxxprovider_tasks_sql "
select	tt.*,
	'' as po_comment,
	tt.task_type_id as po_task_type_id,
	tt.billable_units as po_billable_units,
	tt.task_uom_id as po_task_uom_id
from	im_trans_tasks tt
where	tt.trans_id = :freelance_id
"


# ---------------------------------------------------------------
# Select and render invoicable items 
# ---------------------------------------------------------------

set sql "
select
	t.task_name,
	t.po_comment,
	t.task_units,
	t.project_id,
	to_char(t.po_billable_units, :number_format) as billable_units,
	t.po_task_uom_id as task_uom_id,
	t.po_task_type_id as task_type_id,
	t.match_x,
	t.match_rep,
	t.match100,
	t.match95,
	t.match85,
	t.match75,
	t.match50,
	t.match0,
	im_category_from_id(t.po_task_type_id) as task_type,
	im_category_from_id(t.po_task_uom_id) as uom_name,
	im_category_from_id(t.task_status_id) as task_status,
	im_category_from_id(t.target_language_id) as target_language,
	im_category_from_id(t.source_language_id) as source_language,
	p.project_name,
	p.project_path,
	p.project_path as project_short_name
from 
	($provider_tasks_sql) t,
	im_projects p
where 
	t.project_id = p.project_id
order by
	project_id, task_id
"


set task_table "
<tr> 
  <td class=rowtitle>[_ intranet-trans-invoices.Task_Name]</td>
  <td class=rowtitle>[_ intranet-trans-invoices.Src]</td>
  <td class=rowtitle>[_ intranet-trans-invoices.Trg]</td>
  <td class=rowtitle>[_ intranet-trans-invoices.XTr]</td>
  <td class=rowtitle>[_ intranet-trans-invoices.Rep]</td>
  <td class=rowtitle>100 %</td>
  <td class=rowtitle>95 %</td>
  <td class=rowtitle>85 %</td>
  <td class=rowtitle>75 %</td>
  <td class=rowtitle>50 %</td>
  <td class=rowtitle>0 %</td>
  <td class=rowtitle>[_ intranet-trans-invoices.Units]</td>
  <td class=rowtitle>[_ intranet-trans-invoices.Type]</td>
</tr>
"

ns_log Notice "before rendering the task list $invoice_id"

set task_table_rows ""
set ctr 0
set colspan 15
set old_project_id 0
db_foreach select_tasks $sql {

    # insert intermediate headers for every project
    if {$old_project_id != $project_id} {
	append task_table_rows "
		<input type=hidden name=select_project value=$project_id>
		<tr><td colspan=$colspan>&nbsp;</td></tr>
		<tr><td class=rowtitle colspan=$colspan>
	          <A href=/intranet/projects/view?project_id=$project_id>$project_short_name</A>:
	          $project_name
	        </td></tr>\n"
	set old_project_id $project_id
    }

    append task_table_rows "
	<tr $bgcolor([expr $ctr % 2])> 
	  <td align=left>$task_name</td>
	  <td align=right>$source_language</td>
	  <td align=right>$target_language</td>
	  <td align=right>$match_x</td>
	  <td align=right>$match_rep</td>
	  <td align=right>$match100</td>
	  <td align=right>$match95</td>
	  <td align=right>$match85</td>
	  <td align=right>$match75</td>
	  <td align=right>$match50</td>
	  <td align=right>$match0</td>
	  <td align=right><nobr>
	    $billable_units $uom_name[im_gif help $po_comment]
	  </nobr></td>
	  <td>$task_type</td>
	</tr>"
    incr ctr
}

if {![string equal "" $task_table_rows]} {
    append task_table $task_table_rows
} else {
    append task_table "<tr><td colspan=$colspan align=center>[_ intranet-trans-invoices.No_tasks_found]</td></tr>"
}

# ---------------------------------------------------------------
# 7. Select and format the sum of the invoicable items
# for a new invoice
# ---------------------------------------------------------------

if {[string equal $invoice_mode "new"]} {

    # start formatting the list of sums with the header...
    set task_sum_html "
        <tr align=center> 
          <td class=rowtitle>[_ intranet-trans-invoices.Order]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.Description]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.Units]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.UOM]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.Rate]</td>
        </tr>
    "

    # Start formatting the "reference price list" as well, even though it's going
    # to be shown at the very bottom of the page.
    #
    set price_colspan 11
    set reference_price_html "
        <tr><td align=middle class=rowtitle colspan=$price_colspan>[_ intranet-trans-invoices.Reference_Prices]</td></tr>
        <tr>
          <td class=rowtitle>[_ intranet-trans-invoices.Company]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.UoM]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.Task_Type]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.Target]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.Source]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.Subject_Area]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.Price]</td>
        </tr>\n"



    # Calculate the sum of tasks (distinct by TaskType and UnitOfMeasure)
    # and determine the price of each line using a custom definable
    # function.
    set task_sum_inner_sql "
select
	sum(t.po_billable_units) as task_sum,
	t.po_task_type_id as task_type_id,
	t.po_task_uom_id as task_uom_id,
	t.source_language_id,
	t.target_language_id,
	p.project_id,
	p.subject_area_id
from
	($provider_tasks_sql) t,
	im_projects p
where
	t.project_id=p.project_id
group by
	t.po_task_type_id,
	t.po_task_uom_id,
	p.company_id,
	p.project_id,
	t.source_language_id,
	t.target_language_id,
	p.subject_area_id
"


    # Take the "Inner Query" with the data (above) and add some "long names" 
    # (categories, client names, ...) for pretty output
    set task_sum_sql "
select
	to_char(s.task_sum, :number_format) as task_sum,
	s.task_type_id,
	s.subject_area_id,
	s.source_language_id,
	s.target_language_id,
	s.task_uom_id,
	c_type.category as task_type,
	c_uom.category as task_uom,
	c_target.category as target_language,
	s.project_id,
	p.project_name,
	p.project_path,
	p.project_path as project_short_name,
	p.company_project_nr as company_project_nr
from
	im_categories c_uom,
	im_categories c_type,
	im_categories c_target,
	im_projects p,
	($task_sum_inner_sql) s
where
	s.task_type_id=c_type.category_id(+)
	and s.task_uom_id=c_uom.category_id(+)
	and s.target_language_id=c_target.category_id(+)
	and s.project_id=p.project_id(+)
order by
	p.project_id
    "


    # Calculate the price for the specific service.
    # Complicated undertaking, because the price depends on a number of variables,
    # depending on client etc. As a solution, we act like a search engine, return 
    # all prices and rank them according to relevancy. We take only the first 
    # (=highest rank) line for the actual price proposal.
    #
    set reference_price_sql "
select 
	pr.relevancy as price_relevancy,
	to_char(pr.price, :number_format) as price,
	pr.company_id as price_company_id,
	pr.uom_id as uom_id,
	pr.task_type_id as task_type_id,
	pr.target_language_id as target_language_id,
	pr.source_language_id as source_language_id,
	pr.subject_area_id as subject_area_id,
	pr.valid_from,
	pr.valid_through,
	c.company_path as price_company_name,
        im_category_from_id(pr.uom_id) as price_uom,
        im_category_from_id(pr.task_type_id) as price_task_type,
        im_category_from_id(pr.target_language_id) as price_target_language,
        im_category_from_id(pr.source_language_id) as price_source_language,
        im_category_from_id(pr.subject_area_id) as price_subject_area
from
	(
		(select 
			im_trans_prices_calc_relevancy (
				p.company_id, :provider_id,
				p.task_type_id, :task_type_id,
				p.subject_area_id, :subject_area_id,
				p.target_language_id, :target_language_id,
				p.source_language_id, :source_language_id
			) as relevancy,
			p.price,
			p.company_id as company_id,
			p.uom_id,
			p.task_type_id,
			p.target_language_id,
			p.source_language_id,
			p.subject_area_id,
			p.valid_from,
			p.valid_through
		from im_trans_prices p
		where
			uom_id=:task_uom_id
			and currency=:currency
		)
	) pr,
	im_companies c
where
	pr.company_id = c.company_id(+)
	and relevancy >= 0
order by
	pr.relevancy desc,
	pr.company_id,
	pr.uom_id
    "


    set ctr 1
    set old_project_id 0
    set colspan 6
    set target_language_id ""
    db_foreach task_sum $task_sum_sql {

	# insert intermediate headers for every project
	if {$old_project_id != $project_id} {
	    append task_sum_html "
		<tr><td class=rowtitle colspan=$price_colspan>
	          <A href=/intranet/projects/view?project_id=$project_id>$project_short_name</A>:
	          $company_project_nr
	        </td></tr>\n"

	    # Also add an intermediate header to the price list
	    append reference_price_html "
		<tr><td class=rowtitle colspan=$price_colspan>
	          <A href=/intranet/projects/view?project_id=$project_id>$project_short_name</A>:
	          $company_project_nr
	        </td></tr>\n"
	
	    set old_project_id $project_id
	}

	# Determine the price from a ranked list of "price list hits"
	# and render the "reference price list"
	set price_list_ctr 1
	set best_match_price 0
	db_foreach references_prices $reference_price_sql {

	    ns_log Notice "new-3: company_id=$provider_id, uom_id=$uom_id => price=$price, relevancy=$price_relevancy"
	    # Take the first line of the result list (=best score) as a price proposal:
	    if {$price_list_ctr == 1} {set best_match_price $price}

	    append reference_price_html "
        <tr>
          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_relevancy $price_company_name</td>
          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_uom</td>
          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_task_type</td>
          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_target_language</td>
          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_source_language</td>
          <td class=$bgcolor([expr $price_list_ctr % 2])>$price_subject_area</td>
          <td class=$bgcolor([expr $price_list_ctr % 2])>$price $currency</td>
        </tr>\n"
	
	    incr price_list_ctr
	}

	# Add an empty line to the price list to separate prices form item to item
	append reference_price_html "<tr><td colspan=$price_colspan>&nbsp;</td></tr>\n"

	append task_sum_html "
	<tr $bgcolor([expr $ctr % 2])> 
          <td>
	    <input type=text name=item_sort_order.$ctr size=2 value='$ctr'>
	  </td>
          <td>
	    <input type=text name=item_name.$ctr size=40 value='$task_type ($target_language)'>
	  </td>
          <td align=right>
	    <input type=text name=item_units.$ctr size=4 value='$task_sum'>
	  </td>
          <td align=right>
	    [im_category_select "Intranet UoM" "item_uom_id.$ctr" $task_uom_id]
	  </td>
          <td align=right>
	    <input type=text name=item_rate.$ctr size=3 value='[string trim $best_match_price]'>
	    <input type=hidden name=item_currency.$ctr value='$currency'>
	    $currency
	  </td>
        </tr>
	<input type=hidden name=item_project_id.$ctr value='$project_id'>
	<input type=hidden name=item_type_id.$ctr value='$task_type_id'>\n"

	incr ctr
    }

} else {

# ---------------------------------------------------------------
# 8. Get the old invoice items for an already existing invoice
# ---------------------------------------------------------------

    set invoice_item_sql "
select
	i.*,
	p.*,
	im_category_from_id(i.item_uom_id) as item_uom,
	p.project_path,
	p.project_path as project_short_name,
	p.project_name
from
	im_invoice_items i,
	im_projects p
where
	i.invoice_id=:invoice_id
	and i.project_id=p.project_id(+)
order by
	i.project_id
"

    # start formatting the list of sums with the header...
    set task_sum_html "
        <tr align=center> 
          <td class=rowtitle>[_ intranet-trans-invoices.Order]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.Description]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.Units]</td>
          <td class=rowtitle>[_ intranet-trans-invoices.UoM]</td>
        </tr>
    "

    set ctr 1
    set old_project_id 0
    set colspan 6
    set target_language_id ""
    db_foreach invoice_item $invoice_item_sql {

	# insert intermediate headers for every project
	if {$old_project_id != $project_id} {
	    append task_sum_html "
		<tr><td class=rowtitle colspan=$colspan>
	          <A href=/intranet/projects/view?project_id=$project_id>$project_short_name</A>:
	          $company_project_nr
	        </td></tr>\n"
	
	    set old_project_id $project_id
	}

	# Add an empty line to the price list to separate prices form item to item
	append reference_price_html "<tr><td colspan=$colspan>&nbsp;</td></tr>\n"
	

	append task_sum_html "
	<tr $bgcolor([expr $ctr % 2])> 
          <td>
	    <input type=text name=item_sort_order.$ctr size=2 value='$sort_order'>
	  </td>
          <td>
	    <input type=text name=item_name.$ctr size=40 value='$item_name'>
	  </td>
          <td align=right>
	    <input type=text name=item_units.$ctr size=4 value='$item_units'>
	  </td>
          <td align=right>
	    <input type=hidden name=item_uom_id.$ctr value='$item_uom_id'>
	    $item_uom
	  </td>
          <td align=right>
	    <input type=text name=item_rate.$ctr size=3 value='[string trim $price_per_unit]'>
	    <input type=hidden name=item_currency.$ctr value='$currency'>
	    $currency
	  </td>
        </tr>
	<input type=hidden name=item_project_id.$ctr value='$project_id'>
	<input type=hidden name=item_type_id.$ctr value='$item_type_id'>\n"

	incr ctr
    }

}


db_release_unused_handles
