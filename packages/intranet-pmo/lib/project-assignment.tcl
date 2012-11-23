ad_page_contract {
    It displays project assignments
} { 
    {-project_id ""}
}

set user_assignment_html ""
set old_user_id 0
db_foreach assignments {
    select item_project_member_id as user_id,im_name_from_id(item_project_member_id) as username, item_value as availability, item_date as start_date,to_char(item_date,'YYMM') as start_date_pretty from im_planning_items where item_project_phase_id = :project_id order by username,start_date
} {
    if {$user_id ne $old_user_id} {
	set user "<a href=\"/intranet/users/view?user_id=$user_id\">$username</a>"
	set old_user_id $user_id
    } else {
	set user "&nbsp;"
    }
    append user_assignment_html "<tr><td>$user</td><td>$start_date_pretty</td><td>$availability</td></tr>"    
}