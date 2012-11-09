ad_page_contract {
    It displays project assignments
} { 
    {-project_id ""}
}

set user_assignment_html ""
set old_user_id 0
db_foreach assignments {
    select user_id,im_name_from_id(user_id) as username, availability, start_date,to_char(start_date,'YYMM') as start_date_pretty from im_project_assignments where project_id = :project_id order by username,start_date
} {
    if {$user_id ne $old_user_id} {
	set user "<a href=\"/intranet/users/view?user_id=$user_id\">$username</a>"
	set old_user_id $user_id
    } else {
	set user "&nbsp;"
    }
    append user_assignment_html "<tr><td>$user</td><td>$start_date_pretty</td><td>$availability</td></tr>"    
}