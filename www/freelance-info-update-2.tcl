# /packages/intranet-freelance/www/admin/users/freelance-info-update-2.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.


ad_page_contract {
    @param user_id
    @author Guillermo Belcic
    @frank.bergann@project-open.com
} {
    user_id:integer,notnull
    { translation_rate "" }
    { editing_rate "" }
    { hourly_rate "" }
    { bank_account "" }
    { bank "" }
    { payment_method "" }
    { note "" }
    { private_note "" }
    { return_url "" }
}

#--------------------------------------------------------------------
# Security and Defaults
#--------------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]

# here we had 'im_freelance_permissions' i change it to 'im_users_permissions' (2004/03/09)

im_user_permissions $current_user_id $user_id view read write admin

if {!$write} {
    ad_return_complaint 1 "<li>You have insufficient privileges to modify user $user_id\
."
    return
}

if {[string equal "" $return_url]} {
    set return_url "/intranet/users/view?user_id=$user_id"
}

#--------------------------------------------------------------------
# Update the base data
#--------------------------------------------------------------------


db_0or1row freelance "select user_id as exist_freelance from im_freelancers where user_id = :user_id"

if { ![info exist exist_freelance] } {
    db_dml insert_freelance "insert into im_freelancers (user_id) values ($user_id)"
}


if [catch {
db_dml sql "
UPDATE
	im_freelancers
SET
    	translation_rate = :translation_rate,
    	editing_rate = :editing_rate,
    	hourly_rate = :hourly_rate,
    	bank_account = :bank_account,
    	bank = :bank,
	payment_method_id = :payment_method,
    	note = :note,
	private_note = :private_note
WHERE
	user_id = :user_id"
} errmsg ] {
     ad_return_complaint "Argument Error" "<ul>$errmsg</ul>"
    return
}

db_release_unused_handles
ad_returnredirect $return_url
