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

# Also accept "user_id_from_search" instead of user_id (the one to edit...)
if [info exists user_id_from_search] { set user_id $user_id_from_search}
set current_user_id [ad_maybe_redirect_for_registration]
im_user_permissions $current_user_id $user_id view read write admin
set return_url [im_url_with_query]
set bgcolor(0) "class=roweven"
set bgcolor(1) "class=rowodd"

# Create an error if the current_user isn't allowed to see the user
if {!$write} {
    ad_return_complaint 1 "<li>You have insufficient privileges to view this user."
    return
}

# ---------------------------------------------------------------
# User Information
# ---------------------------------------------------------------

db_0or1row user_full_name "select first_names, last_name from persons where person_id = :user_id"

set page_title "$first_names $last_name"
if {[im_permission $current_user_id view_users]} {
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
	im_categories 
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

if {$write} {
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

    if {$write } { 
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

if {[im_permission $current_user_id admin_categories]} {
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
