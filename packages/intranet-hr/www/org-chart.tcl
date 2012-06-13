# /www/intranet/employees/org-chart.tcl

ad_page_contract {
    by philg@mit.edu on July 6, 1999

    uses CONNECT BY on the supervisor column in im_employees to query 
    out the org chart for a company
    than one person without a supervisor. We figure the Big Kahuna
    is the person with no supervisor AND no subordinates
    Changed display style from indented list to nested table.
    May 11, 2000

    @param starting_user_id if exists: starting user of org chart
    @author Mark Dettinger <dettinger@arsdigita.com>
    @creation-date 
    @cvs-id org-chart.tcl,v 3.15.2.8 2000/09/22 01:38:30 kevin Exp
} {
    { starting_user_id:integer "" }
}

set user_id [ad_maybe_redirect_for_registration]
set context_bar [im_context_bar [list /intranet/users/ "Users"] "Org Chart"]
set page_title "[_ intranet-hr.Users]"
set page_focus "im_header_form.keywords"
set user_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set return_url [im_url_with_query]

if {![im_permission $user_id view_hr]} {
    ad_return_complaint 1 "[_ intranet-hr.lt_You_dont_have_permiss_1]"
    return
}

# Need to find the true big kahuna
# Note that the following query requires! that employees also exist in the
# im_employees - basically, until you say This user is supervised by nobody
# or by her, that user won't show up in the query

set big_kahuna_list [db_list kahuna_find "
select 
	info.employee_id 
from
	im_employees_active info
where
	supervisor_id is null
	and exists (
		select 1
                from im_employees_active info2
                where info2.supervisor_id = info.employee_id
	)
"]

if { [llength $big_kahuna_list] == 0 || [llength $big_kahuna_list] > 1 } {
    ad_return_error "[_ intranet-hr.No_Big_Kahuna]" "<blockquote>[_ intranet-hr.lt_For_the_org_chart_pag]</blockquote>"
    return
}

if { ![exists_and_not_null starting_employee_id] } {
    set starting_employee_id [lindex $big_kahuna_list 0]
}

set page_body "<blockquote>\n"

# this is kind of inefficient in that we do a subquery to make
# sure the employee hasn't left the company, but you can't do a 
# JOIN with a CONNECT BY

#
# there's a weird case when a manager has left the company.  
# we can't just leave him blank because
# it screws the chart up, therefore put in a placeholder "vacant"
#

set last_level 0   ;#level of last employee
set vacant_position ""

set nodes_sql "
select 
    employee_id,
    im_name_from_user_id(employee_id) as employee_name,
    ad_group_member_p(employee_id, [im_employee_group_id]) as currently_employed_p
from 
    im_employees
start with 
    employee_id = :starting_employee_id
connect by  
    supervisor_id = PRIOR employee_id"

set bind_vars [ns_set create]
ns_set put $bind_vars starting_employee_id $starting_employee_id

# generate the org chart

append page_body [tree_to_horizontal_table [im_prune_org_chart [db_tree nodes_display $nodes_sql -bind $bind_vars]] im_print_employee]

# Now pull out the people who don't get included because they 
# aren't starting_employee_id and they don't have supervisors

set employee_listing_sql "
	select	u.employee_id, 
		im_name_from_user_id(u.employee_id) as employee_name
           from im_employees_active u
          where u.employee_id <> :starting_employee_id
            and u.supervisor_id is null
          order by lower(employee_name)"

set homeless_employees ""

db_foreach employee_listing $employee_listing_sql {
    append homeless_employees "  <li> <a href=../users/view?[export_url_vars employee_id]>$employee_name</a>"
    if { $user_admin_p } {
	append homeless_employees " (<a href=admin/update-supervisor?[export_url_vars employee_id return_url]>[_ intranet-hr.add_supervisor]</a>)"
    }
    append homeless_employees "\n"
}

if { ![empty_string_p $homeless_employees] } {
    append page_body "<p><h3>[_ intranet-hr.lt_Employees_without_sup]</h3>
<ul>
$homeless_employees
</ul>
"
}
append page_body "</blockquote>\n"


set page_body "
<BR>
[im_user_navbar "none" "/intranet/users/index" "" "" [list starting_employee_id]]

$page_body
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]
