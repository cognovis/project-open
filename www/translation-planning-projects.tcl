# /packages/intranet-reporting/www/translation-planning-projects.tcl
#
# Copyright (c) 2009 Laurent Léonard (Open-minds)
#
# All rights reserved. 
# Please see http://www.project-open.com/ for licensing.

ad_page_contract {
    
} {
    { date [dt_sysdate] }
    { person_id 0 }
}

set current_user_id [ad_maybe_redirect_for_registration]

set menu_label "reporting"

set read_p [db_string report_perms "
        select  im_object_permission_p(m.menu_id, :current_user_id, 'read')
        from    im_menus m
        where   m.label = :menu_label
" -default 'f']

if {![string equal "t" $read_p]} {
    ad_return_complaint 1 "<li>[lang::message::lookup "" intranet-reporting.You_dont_have_permissions "You don't have the necessary permissions to view this page"]"
    return
}

set page_title "Translation Planning Projects"
set context_bar [im_context_bar $page_title]

ns_write "[im_header]
[im_navbar]\n"

ns_write "<p><a href=\"translation-planning?date=$date\">Back to Translation Planning</a></p>\n"

ns_write "<p>Date: $date<br />Person: [db_string person "SELECT im_name_from_user_id(:person_id)"]</p>"

set sql "
SELECT DISTINCT
	p.*,
	im_category_from_id(p.project_type_id) AS project_type,
	c.company_name
FROM
	im_projects p,
	im_trans_tasks t,
	im_companies c,
	cc_users u
WHERE
	t.project_id = p.project_id
	AND p.company_id = c.company_id
	AND t.task_status_id <> 372
	AND u.person_id = :person_id
	AND u.member_state = 'approved'
	AND (
		t.trans_id = :person_id
		AND DATE(t.end_date) = :date
		OR t.edit_id = :person_id
		AND DATE(p.end_date) = :date
		OR t.proof_id = :person_id
		AND DATE(p.end_date) = :date
	)
ORDER BY
	p.project_nr DESC
"

ns_write "<table>
  <thead>
    <tr>
      <th class=\"rowtitle\">Project Nr.</th>
      <th class=\"rowtitle\">Project Name</th>
      <th class=\"rowtitle\">Customer</th>
      <th class=\"rowtitle\">Type</th>
      <th class=\"rowtitle\">Size</th>
    </tr>
  </thead>
  <tbody>\n"

set bgcolor(0) " class=\"roweven\""
set bgcolor(1) " class=\"rowodd\""
set ctr 1

db_foreach select_projects $sql {
	ns_write "    <tr$bgcolor([expr $ctr % 2])>
      <td><a href=\"../../intranet/projects/view?project_id=$project_id\">$project_nr</a></td>
      <td><a href=\"../../intranet/projects/view?project_id=$project_id\">$project_name</a></td>
      <td><a href=\"../../intranet/companies/view?company_id=$company_id\">$company_name</a></td>
      <td>$project_type</td>
      <td>$trans_size</td>
    </tr>\n"
	incr ctr
}

ns_write "  </tbody>
</table>
[im_footer]\n"
