# /packages/intranet-customer-portal/www/wizard/index.tcl
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


# ---------------------------------------------------------------
# Create a table that shows all files already uploaded
# ---------------------------------------------------------------

if { "" != $inquiry_id } {

    db_1row get_cnt "select count(*) as files_count from im_inquiries_files"

    set row_count 0
    db_multirow files file_query {
        select
                i.*,
                (select project_name from im_projects where project_id=i.project_id) as project_name
        from
                im_inquiries_files i
        where
                i.inquiry_id = :inquiry_id
    } {
	incr row_count
    }
}

