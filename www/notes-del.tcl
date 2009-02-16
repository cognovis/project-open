# /packages/intranet-notes/www/notes-del.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
# 060427 avila@digiteix.com
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# 1. Page Contract
# ---------------------------------------------------------------
ad_page_contract { 
    delete notes

    @param project_id
           project on note is going to create

    @author avila@digiteix.com
} {

    project_id:integer,optional
    { return_url "/intranet-notes/"}
    note_id:multiple,optional
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]

if {[info exists note_id]} {
	foreach id $note_id {

	    # delete note
	    # 
	    db_transaction {
		db_string del_note {}
	    }
	}
}

template::forward "$return_url?[export_vars -url project_id]"
