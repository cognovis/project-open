# /packages/intranet-freelance/www/intranet-freelance/skill-edit.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Display information about one user
    (makes heavy use of procedures in /tcl/ad-user-contributions-summary.tcl)
    @cvs-id languages-recon.tcl
    @author Guillermo Belcic
    @author frank.bergmann@project-open.com
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

# Permission Semantics
# read: Can see the skills
# write: Can "claim" skills
# admin: Can "confirm" skills


# Check whether we are editing ourself...
# There are special conditions for this case...
set self_p 0
if {$user_id == $current_user_id} { 
    set self_p 1 
    set admin 0
}


set return_url [im_url_with_query]
set bgcolor(0) "class=roweven"
set bgcolor(1) "class=rowodd"

# Create an error if the current_user isn't allowed to see the user
if {!$read} {
    ad_return_complaint 1 "<li>[_ intranet-freelance.lt_You_have_insufficient]"
    return
}


# Check permissions to see and modify freelance skills and their confirmations
#
set view_freelance_skills_p [im_permission $current_user_id view_freelance_skills]
set add_freelance_skills_p [im_permission $current_user_id add_freelance_skills]
set view_freelance_skillconfs_p [im_permission $current_user_id view_freelance_skillconfs]
set add_freelance_skillconfs_p [im_permission $current_user_id add_freelance_skillconfs]



# ---------------------------------------------------------------
# User Information
# ---------------------------------------------------------------

db_0or1row user_full_name "
	select	im_name_from_user_id(person_id) as user_name
	from	persons
	where	person_id = :user_id
"

set page_title $user_name
if {[im_permission $current_user_id view_users]} {
    set context_bar [im_context_bar [list /intranet/users/view?user_id=$user_id "$page_title"] "[_ intranet-freelance.Confirmations]"]
} else {
    set context_bar [im_context_bar $page_title]
}

# use [info exists ] here?
if { [empty_string_p $user_name] } {
    ad_return_complaint 1 "<li>[_ intranet-freelance.lt_We_couldnt_find_user_]"
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
	im_category_from_id(s.claimed_experience_id) as claimed_experience,
	im_category_from_id(s.confirmed_experience_id) as confirmed_experience
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
	  <td class=rowtitle>[_ intranet-freelance.Claimed]</td>\n"
if {$view_freelance_skillconfs_p} {
    append skill_table_header "
	  <td class=rowtitle>[_ intranet-freelance.Confirmed]</td>\n"
}
append skill_table_header "
	  <td class=rowtitle align=center>[im_gif delete]</td>
	</tr>
"

set skill_table ""
set ctr 0
db_foreach column_list $sql {

    if {[string equal "Unconfirmed" $confirmed_experience]} {
	set confirmed_experience "&nbsp;"
    }

    append skill_table "
	<tr$bgcolor([expr $ctr % 2])>
	  <td>$skill_name</td>
	  <td>
[im_category_select_plain -include_empty_p 0 "Intranet Experience Level" "claimed.$skill_id" $claimed_experience_id]
	  </td>"

    if {$admin && $add_freelance_skillconfs_p} { 
        append skill_table "
	  <td>
[im_category_select_plain -include_empty_p 0 "Intranet Experience Level" "confirmed.$skill_id" $confirmed_experience_id]
	  </td>\n"
    } else {
        if {$view_freelance_skillconfs_p} {
            append skill_table "<td>$confirmed_experience</td>\n"
        }
    }

    append skill_table "
	  <td>
<input type=checkbox name=\"skill_deleted.$skill_id\" value=\"$skill_id\">
	  </td>
	</tr>"
    incr ctr
}

ns_log Notice "skill_table='$skill_table'"

if {"" != $skill_table} {
    append skill_table "
	<tr>
	  <td></td>
	  <td colspan=[expr 1+$view_freelance_skillconfs_p] align=center>
	    <input type=submit name=button_update value=\"[_ intranet-freelance.Update]\" name=submit>
	  </td>
	  <td>
	    <input type=submit name=button_del value=\"[_ intranet-freelance.Del]\" name=submit>
	  </td>
	</tr>"
} else {
    # No skills yet added
    append skill_table "
	<tr>
	  <td colspan=4 align=center>
            [_ intranet-freelance.lt_There_are_currently_n_1]
	  </td>
	</tr>"
}

# ---------------------------------------------------------------
# Add the "Add Skill" rows
# ---------------------------------------------------------------

append skill_table "
	<tr>
	  <td class=rowtitle align=center colspan=4>
	    [_ intranet-freelance.Add_new_skill_type]"

if {[im_permission $current_user_id admin_categories]} {
    append skill_table "
<A HREF=\"/intranet/admin/categories/?select_category_type=[ns_urlencode $value_range_category_type]\">
        [im_gif new "Add a new %value_range_category_type%"]
	</A>"
}
append skill_table "
	  </td>
	</tr>
	<tr>
	  <td>
[im_category_select_plain -translate_p 0 -include_empty_p 0 $value_range_category_type "add_skill_id" ""]
	  </td>
	  <td colspan=3>
	    <input type=submit name=button_add value=\"[_ intranet-freelance.Add]\" name=submit>
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
ad_return_template

