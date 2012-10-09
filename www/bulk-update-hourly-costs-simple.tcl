# /packages/intranet-core/users/index.tcl
#
# Copyright (C) 1998-2012 various parties
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

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Performs an bulk update of hourly rates using hourly rate as set in SKILL USERS
    SKILL USERS are all users belonging to group "Skill Profile"

    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)

} {
    { mapping_field:trim "username" }
    { skill_profile_group_id:integer -1}
}

if { -1 == $skill_profile_group_id } {
    set skill_profile_group_id [db_string get_data "select group_id from groups where group_name='Skill Profile'" -default -1]
}

if { -1 == $skill_profile_group_id } {
    ad_return_complaint 1 "Group: Skill Profile not found"
}


# getting hourly cost of SKILL USER

set sql "
        select
		u.username,
		e.hourly_cost
        from
                persons p,
                cc_users u
                        LEFT JOIN im_employees e ON (u.user_id = e.employee_id)
                        LEFT JOIN users_contact c ON (u.user_id = c.user_id),
                (select member_id from group_distinct_member_map m where group_id = :skill_profile_group_id) m
        where
                p.person_id = u.user_id
                and u.user_id = m.member_id
                and u.member_state = 'approved'
"

# Setting array
db_foreach get_cost_arr $sql {
	set username_arr($username) $hourly_cost	
} 


# Update each active employee
set sql "
	select 
                e.employee_id,
                e.hourly_cost,
		cc.username,
		cc.first_names,
		cc.last_name,
		u.username as profile_username
	from	
		acs_rels r, 
		membership_rels mr, 
		im_employees e,
		cc_users cc,
		users u
	where 	
		r.rel_id = mr.rel_id and 
		r.object_id_one = 463 and 
		mr.member_state = 'approved' and 
		r.rel_type = 'membership_rel' and
		cc.member_state = 'approved' and 
		r.object_id_two = e.employee_id and 
		e.employee_id = cc.user_id
"

db_foreach row $sql {
	# find hourly cost of according SKILL USER
	set new_hourly_cost username_arr($username)		
	ns_write "Found new hourly cost: $new_hourly_cost for user: <a href="/intranet/users/view?user_id=$employee_id">$first_names $$last_name</a> -> skill profile: $username"
	if { "" == $new_hourly_cost } {
		ns_write "WARNING: No value for hourly cost found, skipping updating"
	} else {
		ns_write "updating .... 
		db_dml update_hourly_cost "update im_employees set hourly_cost = :new_hourly_cost where employee_id = :employee_id"	
	}
}

ns_write "<br><br>Update complete"
