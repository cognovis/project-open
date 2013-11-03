# /packages/intranet-freelance/www/skill-del.tcl
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
    skill_id:integer,multiple
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set object_type [db_string acs_object_type "select object_type from acs_objects where object_id=:object_id"]
set perm_cmd "${object_type}_permissions \$current_user_id \$object_id object_view object_read object_write object_admin"
eval $perm_cmd

# Create an error if the current_user isn't allowed to modify the object
if {!$object_write} {
    ad_return_complaint 1 "<li>[_ intranet-freelance.lt_You_have_insufficient]"
    return
}

# ---------------------------------------------------------------
#
# ---------------------------------------------------------------

lappend skill_id 0

db_dml delete "
                delete from im_object_freelance_skill_map
                where
                        object_id = :object_id
                        and skill_type_id = :skill_type_id
                        and skill_id in ([join $skill_id ","])
"

ad_returnredirect $return_url

