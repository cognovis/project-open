# /packages/intranet-customer-portal/www/get-target-languages.tcl
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
    {inquiry_id ""}
}



set user_id [ad_maybe_redirect_for_registration]

# ---------------------------------------------------------------
# Returns inquiries as JSON 
# ---------------------------------------------------------------

db_1row get_cnt "select count(*) as inquiries_count from im_inquiries_customer_portal"

set row_count 0
db_multirow -extend { prospect_project_type } target_languages target_lang_query {
    	select 
		category_id,
    		category
	from 
		im_categories 
	where 
		category_type = 'Intranet Translation Language' 
		and enabled_p = 't' 
	order 
		by category;
} {
	incr row_count
}
