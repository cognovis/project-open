# /packages/intranet-freelance/www/intranet/users/skill-update.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Accepts "Update", "Del" and "Add" buttons from skill-edit.
    @author Guillermo Belcic
    @author frank.bergmann@project-open.com
} {
    user_id:integer,optional,notnull
    user_id_from_search:integer,optional,notnull
    skill_type_id:integer,notnull
    claimed:array,optional
    confirmed:array,optional
    skill_deleted:array,optional
    { add_skill_id:integer ""}
    { submit "" }
    { return_url "" }
    { button_add "" }
    { button_del "" }
    { button_update "" }
}

# ---------------------------------------------------------------
# Security
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

if {!$write} {
    ad_return_complaint 1 "<li>[_ intranet-freelance.lt_You_have_insufficient_3]"
    return
}

# ---------------------------------------------------------------
# Defaults
# ---------------------------------------------------------------

set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]
set bgcolor(0) "class=roweven"
set bgcolor(1) "class=rowodd"

if {[string equal "" $return_url]} {
    set return_url "/intranet/users/view?user_id=$user_id"
}

# ---------------------------------------------------------------
# Deal with Update, Del and Add commands
# ---------------------------------------------------------------

# Deal with multilingual button "values"
if {"" != $button_add} { set submit "Add" }
if {"" != $button_del} { set submit "Del" }
if {"" != $button_update} { set submit "Update" }

switch $submit {

    "Update" {
	set return_url "/intranet/users/view?user_id=$user_id"
	
	# ------------------- Update Claimed Experience ------------
	set claimed_list [array names claimed]
	foreach claimed_skill_id $claimed_list {
	    if {"" == $claimed_skill_id} { continue }
	    if {"" == $claimed($claimed_skill_id)} { continue }

	    set sqlclaimed "
	update
		im_freelance_skills
	set
		claimed_experience_id=$claimed($claimed_skill_id)
	where
		user_id=:user_id
		and skill_id=:claimed_skill_id
		and skill_type_id=:skill_type_id"

	    if [catch {db_dml update_experience $sqlclaimed} errmsg] {
		ad_return_complaint "[_ intranet-freelance.DB_Error]" "
                <li>[_ intranet-freelance.lt_Error_updating_experi]: $errmsg"
	    }
	}

	# ------------------- Update Confirmed Experience ------------
	if {$admin} {
	    set confirmed_list [array names confirmed]
	    foreach confirmed_skill_id $confirmed_list {
		if {"" == $confirmed_skill_id} { continue }
		if {"" == $confirmed($confirmed_skill_id)} { continue }

		set sqlconfirmed "
        update
                im_freelance_skills
        set
                confirmed_experience_id=$confirmed($confirmed_skill_id),
		confirmation_user_id=$current_user_id,
		confirmation_date=to_date('$todays_date','YYYY-MM-DD')
        where
                user_id=:user_id
                and skill_id=:confirmed_skill_id
                and skill_type_id=:skill_type_id"

		if [catch {db_dml update_experience $sqlconfirmed} errmsg] {
		    ad_return_complaint "[_ intranet-freelance.DB_Error]" "
                <li>[_ intranet-freelance.lt_Error_updating_experi]: $errmsg"
		}
	    }
	}
    }
    
    "Del" {
	# ------------------- Delete selected Skills ------------
	set delete_list [array names skill_deleted]
	foreach delete_skill $delete_list {
	    set sqldelete "
		delete
		from
			im_freelance_skills
		where
			user_id=:user_id
			and skill_id=:delete_skill
			and skill_type_id=:skill_type_id
"
	    if [catch {db_dml delete_skill $sqldelete} errmsg] {
		ad_return_complaint "[_ intranet-freelance.DB_Error]" "
               <li>[_ intranet-freelance.lt_Error_updating_experi]: $errmsg"
	    }
	}
    }

    "Add" {
	# ------------------- Add a new skill to the list ------------

	if {"" == $add_skill_id} {
	    ad_return_complaint "[_ intranet-freelance.Error]" "
               <li>Please specify a skill to add to the list of skills."
	}

	set unconfirmed_experience [db_string unconfirmed_experience "select category_id from im_categories where category_type='Intranet Experience Level' and category='Unconfirmed'"]

	set sql "
insert into im_freelance_skills (
	user_id, 
	skill_id, 
	skill_type_id, 
	confirmed_experience_id
) values (
	:user_id, 
	:add_skill_id, 
	:skill_type_id,
	:unconfirmed_experience
)"

       if [catch { db_dml insert_freelance_skills $sql } errmsg] {
    ad_return_complaint "[_ intranet-freelance.DB-Error]" "<li>[_ intranet-freelance.lt_The_database_choked_o]:
    <blockquote>$errmsg</blockquote>"
        }
    }
}


db_release_unused_handles
ad_returnredirect $return_url
