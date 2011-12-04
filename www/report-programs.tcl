# /packages/intranet-reporting-openoffice/www/report-portfolio.tcl
#
# Copyright (C) 2003 - 2011 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Return a HTML or OpenOffice document with a list of programs
    and their parameters.
    @author frank.bergmann@project-open.com
} {
    { template "project-oneslide.odp" }
    { output_format "odp" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# Get user parameters
set user_id [ad_maybe_redirect_for_registration]
set user_locale [lang::user::locale]
set date_format "YYYY-MM-DD"

if {0} {
    ad_return_complaint 1 "<li>[lang::message::lookup $locale intranet-invoices.lt_You_need_to_specify_a]"
    return
}

set page_title [lang::message::lookup "" intranet-reporting-openoffice.Program_Overview "Program Overview"]
set context [list $page_title]
set sub_navbar_html ""
set left_navbar_html ""


# ---------------------------------------------------------------
# Table header
# ---------------------------------------------------------------

# ADP Tempate for rendering one row
set header_fields {
    Customer
    Program
    {Start <br> End}
    {Percent <br> Completed}
}

set table_header_html ""
foreach field $header_fields {
    append table_header_html "<td>$field</td>\n"
}
set table_header_html "<tr>\n$table_header_html</tr>\n"


# ---------------------------------------------------------------
# Table Body
# ---------------------------------------------------------------

set body_fields {
    @company_name@
    @project_name@
    {@start_date_pretty@ <br> @end_date_pretty@}
    @program_percent_completed@
}

set body_template_html ""
foreach field $body_fields {
    append body_template_html "<td>$field</td>\n"
}
set body_template_html "<tr>\n$body_template_html</tr>\n"


# ---------------------------------------------------------------
# Render the table
# ---------------------------------------------------------------

set derefs "
	,im_category_from_id(prog.project_status_id) as project_status
"

set program_sql "
	select	prog.*,
		to_char(prog.start_date, :date_format) as start_date_pretty,
		to_char(prog.end_date, :date_format) as end_date_pretty,
		(	select	round(10.0 * avg(percent_completed)) / 10.0
			from	im_projects p
			where	p.program_id = prog.project_id and
				p.project_status_id in (select * from im_sub_categories([im_project_status_open]))
		) as program_percent_completed,
		cust.company_name,
		cust.company_path as company_nr,
		cust.company_id

		$derefs 
	from	im_projects prog,
		im_companies cust
	where	prog.company_id = cust.company_id and
		prog.project_type_id = [im_project_type_program]
	order by
		lower(prog.project_name)
"

#		and prog.project_status_id in (select * from im_sub_categories([im_project_status_open]))

set table_body_html ""
db_foreach programs $program_sql {
    eval [template::adp_compile -string $body_template_html]
    append table_body_html $__adp_output
}

