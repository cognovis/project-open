# /packages/intranet-core/www/companies/new.tcl
#
# Copyright (C) 1998-2004 various parties
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
    Lets users add/modify information about our companies.
    Contact details are not stored with the company itself,
    but with a "main_office" that is a required property
    (not null).

    @param company_id if specified, we edit the company with this company_id
    @param return_url Return URL

    @author mbryzek@arsdigita.com
    @author frank.bergmann@project-open.com
    @author juanjoruizx@yahoo.es
} {
    { company_id:integer 0 }
    { return_url "" }
}

set user_id [ad_maybe_redirect_for_registration]
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set required_field "<font color=red size=+1><B>*</B></font>"


# Make sure the user has the privileges, because this
# pages shows the list of companies etc.
#
if {![im_permission $user_id "add_companies"]} { 
   ad_return_complaint "Insufficient Privileges" "
  <li>You don't have sufficient privileges to add a new company."
}

if {$company_id > 0} {

    # Called with an existing company_id => Edit the company
    # We know that main_office_id is NOT NULL...

    if {![db_0or1row company_get_info "
select
	c.company_name, 
	c.company_path, 
	c.company_status_id, 
	c.company_type_id, 
	c.main_office_id,
	c.billable_p,
	c.note, 
	c.annual_revenue_id, 
	c.referral_source,
	c.vat_number,
	c.manager_id,
	c.site_concept, 
	c.contract_value as contract_value,
	to_char(c.start_date,'YYYY-MM-DD') as start_date,
	o.phone,
	o.fax,
	o.address_line1,
	o.address_line2,
	o.address_city,
	o.address_postal_code,
	o.address_country_code
from 
	im_companies c, 
	im_offices o
where 
	c.company_id=:company_id
	and c.main_office_id=o.office_id
" 
    ]} {
	ad_return_complaint 1 "<li>Company doesn't exist."
	return
    }

    set page_title "Edit Company"
    set context_bar [ad_context_bar [list index "Companies"] [list "view?[export_url_vars company_id]" "One company"] $page_title]

} else {
    # Completely new company. Set some reasonable defaults:
    set page_title "Add Company"
    set context_bar [ad_context_bar [list index "Companies"] $page_title]
    set company_name ""
    set company_path ""
    # Grab today's date
    set start_date [lindex [split [ns_localsqltimestamp] " "] 0]
    set note ""
    set phone ""
    set fax ""
    set address_line1 ""
    set address_line2 ""
    set address_postal_code ""
    set address_city ""
    set site_concept ""
    set vat_number ""

    set company_status_id [im_company_status_active]
    set company_type_id [im_company_type_other]
    set annual_revenue_id [im_company_annual_rev_1_10]
    set referral_source "How did we get in contact with the company?"
    set billable_p "t"
    set "creation_ip_address" [ns_conn peeraddr]
    set "creation_user" $user_id
    set company_id [im_new_object_id]
    set address_country_code ""
    set manager_id ""
}

set company_defaults [ns_set create]
ns_set put $company_defaults billable_p $billable_p


set page_body "
<form method=post action=new-2>
[export_form_vars return_url company_id creation_ip_address creation_user main_office_id]
		  <table border=0>
		    <tr> 
		      <td colspan=2 class=rowtitle align=center>Add New Company</td>
		    </tr>
		    <tr> 
		      <td>Company Name</td>
		      <td> 
<input type=text size=30 name=company_name value=\"$company_name\">
		      </td>
		    </tr>
		    <tr> 
		      <td>Company Short Name<BR><font size=-2>(directory path)</font></td>
		      <td> 
<input type=text size=10 name=company_path value=\"$company_path\">
		      </td>
		    </tr>
		    <tr> 
		      <td>Referral Source</td>
		      <td> 
<input type=text size=30 name=referral_source value=\"$referral_source\">
		      </td>
		    </tr>
		    <tr> 
		      <td>Company Status</td>
		      <td> 
[im_company_status_select "company_status_id" $company_status_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Company+Status'>
	[im_gif new {Add a new company status}]</A>"
}

append page_body "
		      </td>
		    </tr>
		    <tr> 
		      <td>Company Type</td>
		      <td> 
[im_company_type_select "company_type_id" $company_type_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Company+Type'>
	[im_gif new {Add a new company type}]</A>"
}

append page_body "
		      </td>
		    </tr>
		    <tr> 
		      <td>Phone</td>
		      <td> 
<input type=text size=15 name=phone value=\"$phone\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>Fax</td>
		      <td> 
<input type=text size=15 name=fax value=\"$fax\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>Address 1</td>
		      <td> 
<input type=text size=30 name=address_line1 value=\"$address_line1\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>Address 2</td>
		      <td> 
<input type=text size=30 name=address_line2 value=\"$address_line2\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>ZIP and City</td>
		      <td> 
<input type=text size=5 name=address_postal_code value=\"$address_postal_code\" >
<input type=text size=30 name=address_city value=\"$address_city\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>Country</td>
		      <td> 
[im_country_select address_country_code $address_country_code]
		      </td>
		    </tr>
		    <tr> 
		      <td>Web Site</td>
		      <td> 
<input type=text size=30 name=site_concept value=\"$site_concept\" >
		      </td>
		    </tr>
		    <tr> 
		      <td>VAT Number</td>
		      <td> 
<input type=text size=20 name=vat_number value=\"$vat_number\" >
		      </td>
		    </tr>


		    <tr> 
		      <td>(Expected) Annual Revenue</td>
		      <td> 
[im_category_select "Intranet Annual Revenue" annual_revenue_id $annual_revenue_id]
"
if {$user_admin_p} {
    append page_body "
	<A HREF='/intranet/admin/categories/?select_category_type=Intranet+Annual+Revenue'>
	[im_gif new {Add a new annual revenue measure}]</A>"
}

append page_body "
		      </td>
		    </tr>
		    <tr> 
		      <td>Is this a billable company?</td>
		      <td> 

<input type=radio name=billable_p value=t> Yes &nbsp;</input>
<input type=radio name=billable_p value=f> No </input>

		      </td>
		    </tr>
		    <tr> 
		      <td>Key Account Manager</td>
		      <td> 
<select name=manager_id size=8>
[im_employee_select_optionlist $manager_id]
</select>
		      </td>
		    </tr>
		    <tr> 
		      <td>Notes</td>
		      <td> 
<textarea name=note rows=6 cols=30 wrap=soft>[philg_quote_double_quotes $note]</textarea>
		      </td>
		    </tr>

</table>

<p><center><input type=submit value=\"$page_title\"></center>
</form>
"

doc_return  200 text/html [im_return_template]
