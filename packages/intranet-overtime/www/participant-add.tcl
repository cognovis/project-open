# /packages/intranet-events/www/participant-add.tcl
#
# Copyright (c) 1998-2008 ]project-open[
# All rights reserved

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    @author frank.bergmann@event-open.com
} {
    event_id:integer
    user_id:integer
    return_url
    {add_nn ""}
    {add_nn_num 0}
    {add_nn_customer_id 0}
    {add_participant ""}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set org_event_id $event_id

set current_user_id [ad_maybe_redirect_for_registration]
im_event_permissions $current_user_id $event_id view read write admin
if {!$write} {
    ad_return_complaint 1 "You don't have the right to modify this event"
    ad_script_abort
}

if {"" != $add_participant} {
    set role_id 1300
    set rel_id [im_biz_object_add_role $user_id $event_id $role_id]
    db_dml update_rel "update im_biz_object_members set member_status_id = [im_event_participant_status_reserved] where rel_id = :rel_id"
}

if {"" != $add_nn} {
    if {"" == $add_nn_customer_id} { 
	ad_return_complaint 1 [lang::message::lookup "" intranet-events.You_need_to_specify_customer "You need to specify cusomer"] 
    }

    # Determine the default email for the customer
    set domain_list [db_list customer_email_list "
	select	substring(pa.email from '@(.*)') as domain,
		count(*) as cnt
	from	parties pa,
		acs_rels r
	where	r.object_id_two = pa.party_id and
		r.object_id_one = :add_nn_customer_id and
		pa.party_id in (select member_id from group_distinct_member_map where group_id = [im_profile_customers])
	group by domain order by cnt DESC
    "]

    set domain [lindex $domain_list 0]
    if {"" == $domain} {
        set customer_nr [db_string cust_name "select customer_path from im_companies where company_id = :add_nn_customer_id" -default "test"]
        set domain "$customer_nr.com"
    }

    set nn_id 1
    for {set i 0} {$i < $add_nn_num} {incr i} {

	set repeat_p 1
	while {$repeat_p} {
	    set first_names "N$nn_id"
	    set last_name "N$nn_id"
	    set email "n$nn_id.n$nn_id@$domain"
	    set username $email
	    set screen_name $email
	    set password $email
	    set url "http://www.$domain/"

	    set repeat_p [db_string email_exists "select count(*) from parties where email = :email"]
	    incr nn_id
	}

	# Now we got reasonable names and email
	
	array set creation_info [auth::create_user \
				     -username $username \
				     -email $email \
				     -first_names $first_names \
				     -last_name $last_name \
				     -screen_name $screen_name \
				     -password $password \
				     -url $url \
				    ]
	if {"ok" != $creation_info(creation_status) || "ok" != $creation_info(account_status)} {
	    ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-events.Failed_to_create_user "Failed to create user"]</b>:<br>
	    <pre>[array get creation_status]</pre>"
	}
	set new_user_id $creation_info(user_id)
	
	# Update creation user to allow the creator to admin the user
	db_dml update_creation_user_id "
		update acs_objects
		set creation_user = :current_user_id
		where object_id = :new_user_id
	"
    
	person::update -person_id $new_user_id -first_names $first_names -last_name $last_name
	party::update -party_id $new_user_id -url $url -email $email
	acs_user::update -user_id $new_user_id -screen_name $screen_name -username $username

        # Add the user to the "Registered Users" group, because
        # (s)he would get strange problems otherwise
        # Use a non-cached version here to avoid issues!
        set registered_users [im_registered_users_group_id]
        set reg_users_rel_exists_p [db_string member_of_reg_users "
		select	count(*) 
		from	group_member_map m, membership_rels mr
		where	m.member_id = :new_user_id
			and m.group_id = :registered_users
			and m.rel_id = mr.rel_id 
			and m.container_id = m.group_id 
			and m.rel_type::text = 'membership_rel'::text
	"]
	if {!$reg_users_rel_exists_p} {
	    relation_add -member_state "approved" "membership_rel" $registered_users $new_user_id
	}

	# Add a im_employees record to the user
	if {[im_table_exists im_employees]} {
	    # Simply add the record to all users, even it they are not employees...
	    set im_employees_exist [db_string im_employees_exist "select count(*) from im_employees where employee_id = :new_user_id"]
	    if {!$im_employees_exist} {
		db_dml add_im_employees "insert into im_employees (employee_id) values (:new_user_id)"
	    }
	}

	# Add a im_freelancers record to the user
	if {[im_table_exists im_freelancers]} {
	    # Simply add the record to all users, even it they are not freelancers...
	    set im_freelancers_exist [db_string im_freelancers_exist "select count(*) from im_freelancers where user_id = :new_user_id"]
	    if {!$im_freelancers_exist} {
		db_dml add_im_freelancers "insert into im_freelancers (user_id) values (:new_user_id)"
	    }
	}

	# Add this guy to customers
	im_profile::add_member -profile_id [im_profile_customers] -user_id $new_user_id

	# Add the user to the company
	set role_id 1300
	set rel_id [im_biz_object_add_role $new_user_id $add_nn_customer_id $role_id]
	db_dml update_rel "update im_biz_object_members set member_status_id = [im_event_participant_status_reserved] where rel_id = :rel_id"

	# Add the user to the event
	set rel_id [im_biz_object_add_role $new_user_id $org_event_id $role_id]
	db_dml update_rel "update im_biz_object_members set member_status_id = [im_event_participant_status_reserved] where rel_id = :rel_id"

    }
}


ad_returnredirect $return_url
