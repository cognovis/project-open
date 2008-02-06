# /packages/intranet-freelance/www/object-skill-add.tcl
#
# Copyright (c) 2003-2008 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Add a new skill to an object's skill map
    @author frank.bergmann@project-open.com
} {
    object_id:integer,notnull
    skill_type_id:integer,notnull
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$current_user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd

# Create an error if the current_user isn't allowed to see the user
if {!$object_write} {
    ad_return_complaint 1 "<li>[_ intranet-freelance.lt_You_have_insufficient]"
    return
}

set page_title [lang::message::lookup "" intranet-freelance.Add_skill "Add Skill"]
set context_bar [im_context_bar $page_title]

set bgcolor(0) "class=roweven"
set bgcolor(1) "class=rowodd"


# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

set skill_category_type [db_string cattype "select coalesce(aux_string1, category_description) from im_categories where category_id = :skill_type_id" -default ""]

set skills_sql "
	select	*
	from	im_categories
	where	category_type = :skill_category_type
		and (enabled_p = 't' OR enabled_p is null)
	order by
		lower(category)
"

db_multirow -extend {checked} skills skills $skills_sql {
    set checked ""
}
