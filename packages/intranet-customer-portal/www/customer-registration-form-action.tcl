# /packages/intranet-customer-portal/www/customer-registration-form-action.tcl
#
# Copyright (C) 2011 ]project-open[
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
    {email ""}
    {first_names ""}
    {last_name ""}
    {password ""}
    {company ""}
    {phone ""}
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

# ---------------------------------------------------------------
# Create inquiry 
# ---------------------------------------------------------------

set inquiry_id [db_string nextval "select nextval('im_inquiries_customer_portal_seq');"]

set str_length 40 
set security_token [subst [string repeat {[format %c [expr {int(rand() * 26) + (int(rand() * 10) > 5 ? 97 : 65)}]]} $str_length]] 

db_dml insert_inq "
	insert into im_inquiries_customer_portal 
		(inquiry_id, first_names, last_names, email, company_name, phone, security_token) 
	values 
		($inquiry_id, :first_names, :last_name, :email, :company, :phone, '$security_token')
"
ns_returnredirect "upload-files.tcl?security_token=$security_token&inquiry_id=$inquiry_id"






