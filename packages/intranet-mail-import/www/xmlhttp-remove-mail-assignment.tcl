# /packages/intranet-mail-import/www/remove-mail-assignment.tcl
#
# Copyright (C) 2003-2013 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Removes mail relationship: User/Project -> mail

    @param object_id 
    @author klaus.hofeditz@project-open.com

} {
    { mail_id }
    { object_id }
} 

set user_id [ad_maybe_redirect_for_registration]
set object_type [db_string object_type "select object_type from acs_objects where object_id= :object_id" -default 0]

# --------------------------------------------------
# Criteria: Who shouldn't be allowed to delete rel 
# --------------------------------------------------

# Object Type not recognized 
if { "" == $object_type } { 
    ns_return 499 text/html "No Object Type found for object_id: $object_id. Please inform your System Administrator" 
    ad_script_abort
}

if { "im_project" == $object_type } {
     # User needs to be member of project needs to have privilege 'View Mails All'
     if { ![im_biz_object_member_p $user_id $object_id] } {
	 ns_return 499 text/html "User does not have permission to remove relationship. Needs to be a member of Project Id: $object_id]"
	 ad_script_abort
     } elseif { ![im_permission [ad_get_user_id] view_mails_all] } {
         ns_return 499 text/html "User does not have permission to remove relationship. Needs privilege: 'View Mails All'"
	 ad_script_abort
     }
}

if { "user" == $object_type } {
   # User needs needs to have privilege 'View Mails All'  
   if { ![im_permission [ad_get_user_id] view_mails_all] } {
       ns_return 499 text/html "User does not have permission to remove relationship. Needs privilege: 'View Mails All'"
       ad_script_abort
   }
}

# --------------------------------------------------
# Remove rel 
# --------------------------------------------------

set sql "
	select 
		r.rel_id 
	from 
		acs_rels r,
		acs_mail_bodies mb
	where 
		r.object_id_one = mb.body_id and 
		mb.content_item_id = :mail_id and 
		r.object_id_two = :object_id
"

if {[catch {
    set rel_id [db_string get_rel $sql -default 0]
} err_msg]} {
    ns_return 499 text/html "Multiple records found: Mail Id: $mail_id, Object Id: $object_id. Please inform your System Administrator: Error: $err_msg"
    ad_script_abort
}
if { 0 == $rel_id } {
    ns_return 499 text/html "Relationship not found: Mail Id: $mail_id, Object Id: $object_id. Please inform your System Administrator" 
    ad_script_abort
} else {
    if {[catch {
	db_dml target_languages "delete from acs_rels where rel_id = :rel_id"
    } err_msg]} {
	ns_return 499 text/html "Not able to delete relationship: Mail Id: $mail_id, Object Id: $object_id. Please inform your System Administrator: Error: $err_msg"
	ad_script_abort
    }
    ns_return 200 text/html "Relationship removed"
}

