# /www/intranet-freelance/skill-edit.tcl

ad_page_contract {
    Display information about one user
    (makes heavy use of procedures in /tcl/ad-user-contributions-summary.tcl)
    @cvs-id languages-recon.tcl
    @author Guillermo Belcic
    @creation-date October 03, 2003
} {
    user_id:integer,optional,notnull
    user_id_from_search:integer,optional,notnull
    skill_type_id:integer,notnull
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set return_url [im_url_with_query]
set bgcolor(0) "class=roweven"
set bgcolor(1) "class=rowodd"

# -------------- Group Memberships ----------------

# Also accept "user_id_from_search" instead of user_id (the one to edit...)
if [info exists user_id_from_search] { set user_id $user_id_from_search}
set current_user_id [ad_maybe_redirect_for_registration]

set current_user_is_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set current_user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $current_user_id]
set current_user_is_employee_p [im_user_is_employee_p $current_user_id]
set current_user_admin_p [expr $current_user_is_admin_p || $current_user_is_wheel_p]

set user_is_customer_p [ad_user_group_member [im_customer_group_id] $user_id]
set user_is_freelance_p [ad_user_group_member [im_freelance_group_id] $user_id]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
set user_is_wheel_p [ad_user_group_member [im_wheel_group_id] $user_id]
set user_is_employee_p [im_user_is_employee_p $user_id]

# Determine the type of the user to view:
set user_type "none"
if {$user_is_freelance_p} { set user_type "freelance" }
if {$user_is_employee_p} { set user_type "employee" }
if {$user_is_customer_p} { set user_type "customer" }
if {$user_is_wheel_p} { set user_type "wheel" }
if {$user_is_admin_p} { set user_type "admin" }


if { 0 } {
# Check if "user" belongs to a group that is administered by 
# the current users
set administrated_user_ids [db_list administated_user_ids "
select
	member_id
from
	group_member_map
where
	group_id in (	select group_id
			from group_member_map
			where member_id = :current_user_id and rel_type like 'admin_rel')"]

set user_in_administered_project 0
if {[lsearch -exact $administrated_user_ids $user_id] > -1} { 
    set user_in_administered_project 1
}

# -------------- Permission Matrix ----------------

# permission_matrix = [$view_user $edit_user]
set permission_matrix [im_user_permission_matrix $current_user_id $user_id $user_type $current_user_admin_p $user_in_administered_project]
set view_user [lindex $permission_matrix 0]
set edit_user [lindex $permission_matrix 1]
set show_admin_links $current_user_admin_p


# Create an error if the current_user isn't allowed to see the user
if {!$edit_user} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You have insufficient privileges to view this user."
    return
}
}

# ---------------------------------------------------------------
# User Information
# ---------------------------------------------------------------

db_0or1row user_full_name "select first_names, last_name from persons where person_id = :user_id"

set page_title "$first_names $last_name"
if {$user_is_employee_p} {
    set context_bar [ad_context_bar_ws [list /intranet/users/view?user_id=$user_id "$page_title"] "Confirmations"]
} else {
    set context_bar [ad_context_bar_ws $page_title]
}

# use [info exists ] here?
if { [empty_string_p $first_names] && [empty_string_p $last_name] } {
    ad_return_complaint 1 "<li>We couldn't find user \#$user_id; perhaps this person was nuke?"
    return
}

# ---------------------------------------------------------------
# Get the skill_type and the value range for the skill
# ---------------------------------------------------------------

# The "value_range" is the category_type of the categories
# that make up the value for this skill_type.
# Maybe this could be an extension of the categories table
# in the future...

db_1row skill_type "
select
	category as skill_type,
	category_description as value_range_category_type
from 
	categories 
where 
	category_type = 'Intranet Skill Type' 
	and category_id=:skill_type_id
"

# ---------------------------------------------------------------
# Freelance skills query
# ---------------------------------------------------------------

set sql "
select
	s.*,
	im_category_from_id(s.skill_id) as skill_name,
	s.claimed_experience_id as claimed,
	s.confirmed_experience_id as confirmed
from
	im_freelance_skills s
where
	user_id = :user_id 
	and skill_type_id = :skill_type_id
order by
	s.skill_id
"

set skill_table_header "
	<tr class=rowtitle>
	  <td class=rowtitle>$skill_type</td>
	  <td class=rowtitle>Claimed</td>\n"

if {$current_user_is_admin_p} {
    append skill_table_header "
	  <td class=rowtitle>Confirmed</td>\n" 
}
append skill_table_header "
	  <td class=rowtitle align=center>[im_gif delete]</td>
	</tr>
"

set skill_table ""
set ctr 0
db_foreach column_list $sql {

    append skill_table "
	<tr$bgcolor([expr $ctr % 2])>
	  <td>$skill_name</td>
	  <td>
[im_category_select "Intranet Experience Level" "claimed.$skill_id" $claimed]
	  </td>"

    if {$current_user_is_admin_p } { 
        append skill_table "
	  <td>
[im_category_select "Intranet Experience Level" "confirmed.$skill_id" $confirmed]
	  </td>\n"
    }

    append skill_table "
	  <td>
<input type=checkbox name=skill_deleted.$skill_id value=$skill_id>
	  </td>
	</tr>"
    incr ctr
}

ns_log Notice "skill_table='$skill_table'"

if {"" != $skill_table} {
    append skill_table "
	<tr>
	  <td></td>
	  <td colspan=2 align=center>
	    <input type=submit value=Update name=submit>
	  </td>
	  <td>
	    <input type=submit value=Del name=submit>
	  </td>
	</tr>"
} else {
    # No skills yet added
    append skill_table "
	<tr>
	  <td colspan=4 align=center>
            There are currently no $skill_type.
	  </td>
	</tr>"
}

# ---------------------------------------------------------------
# Add the "Add Skill" rows
# ---------------------------------------------------------------

append skill_table "
	<tr>
	  <td class=rowtitle align=center colspan=4>
	    Add new $skill_type\n"

if {$current_user_admin_p} {
    append skill_table "
<A HREF=\"/admin/categories/?select_category_type=[ns_urlencode $value_range_category_type]\">
        [im_gif new "Add a new $value_range_category_type"]
	</A>"
}
append skill_table "
	  </td>
	</tr>
	<tr>
	  <td>
[im_category_select $value_range_category_type "add_skill_id" ""]
	  </td>
	  <td colspan=3>
	    <input type=submit value=\"Add\" name=submit>
	  </td>
	</tr>
"

# ---------------------------------------------------------------
# Join everything together
# ---------------------------------------------------------------

set page_body "
<form method=POST action=skill-update>
[export_form_vars user_id skill_type_id return_url]
<table>
  $skill_table_header
  $skill_table
</table>
</form>
"

db_release_unused_handles
doc_return  200 text/html [im_return_template]
