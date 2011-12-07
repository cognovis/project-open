# /packages/intranet-customer-portal/www/financial-document-store.tcl
#
# Copyright (C) 2011 ]project-open[
# The code is based on ArsDigita ACS 3.4
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

ad_page_contract {
    @param
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} { 
	start:integer 
	limit:integer 
}

# ---------------------------------------------------------------
# Defaults & Security  
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set row_count 0
set cost_type_id_invoice [db_string get_data "select category_id from im_categories where category_type = 'Customer Invoice'" -default 3700] 
set docs_count 0

# ---------------------------------------------------------------
# Body
# ---------------------------------------------------------------

# we assume that user is member of only one company 
set sql "
	select
		a.object_id_one as company_id
	from
		acs_rels a
	where
		object_id_two = $user_id and
		rel_type = 'im_company_employee_rel'
	limit 1
"

if { [catch {
        db_1row get_company_data $sql
} err_msg] } {
	ns_return 200 text/html "\{\"totalCount\":\"0\"\}"
}

# security: user must be either "Key Account" or "Accounting Contact" ToDo: ... or listed in package parameter
set user_is_primary_contact_or_accounting_contact [db_string get_view_id "select count(*) from im_companies where (primary_contact_id = :user_id or accounting_contact_id = :user_id) and company_id = $company_id" -default 0]
if { !$user_is_primary_contact_or_accounting_contact } {  
	ns_return 200 text/html "\{\"totalCount\":\"0\"\}"

} else {
    set cur_format [im_l10n_sql_currency_format -locale en]
    set doc_query "
	select
	        i.invoice_id as id,
	        o.object_type,
		ci.cost_name,
	        ci.currency as invoice_currency,
	        pr.project_nr,
		pr.project_id,
		to_char(ci.effective_date, 'YYYY-MM-DD') as doc_date,
	        to_char(ci.amount * (1 + coalesce(ci.vat,0)/100 + coalesce(ci.tax,0)/100), '$cur_format') as invoice_amount_formatted,
	        im_category_from_id(i.invoice_status_id) as status_id,
	        im_category_from_id(i.cost_type_id) as cost_type, 
		ci.template_id
	from
	        im_invoices_active i,
	        im_costs ci
		        LEFT OUTER JOIN im_projects pr on (ci.project_id = pr.project_id),
	        acs_objects o,
	        im_companies c,
	        im_companies p
	where
	        i.invoice_id = o.object_id
	        and i.invoice_id = ci.cost_id
	        and i.customer_id=c.company_id
	        and i.provider_id=p.company_id
		and c.company_id = $company_id
		and i.cost_type_id = $cost_type_id_invoice
	order by 
		i.invoice_id
	limit   :limit
	offset  :start 
	"
	db_multirow -extend { invoice_status } docs doc_query $doc_query {
	    	set invoice_status [im_category_from_id $status_id]
	
		if { ""==$cost_name } { 
		        set cost_name "---" 
		} else {
	                set cost_name "<a href='/intranet-invoices/view?invoice_id=$id&render_template_id=$template_id'>$cost_name</a>"
		}
		set project_nr "<a href='/intranet/projects/view?project_id=$project_id'>$project_nr</a>"
		incr row_count
	}
	
	set sql "
	select 
		count(*)
	from
	        im_invoices_active i,
	        im_costs ci
	                LEFT OUTER JOIN im_projects pr on (ci.project_id = pr.project_id),
	        acs_objects o,
	        im_companies c,
	        im_companies p
	where
	        i.invoice_id = o.object_id
	        and i.invoice_id = ci.cost_id
	        and i.customer_id=c.company_id
	        and i.provider_id=p.company_id
	        and c.company_id = $company_id
                and i.cost_type_id = $cost_type_id_invoice
	"
	if { 0 != $row_count} {
		set docs_count [db_string get_count $sql -default 0]
	}
}