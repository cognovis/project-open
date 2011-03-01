# /packages/intranet-notes/www/action.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Takes commands from the /intranet-notes/index page or 
    the notes-list-compomponent and perform the selected 
    action an all selected notes.
    @author frank.bergmann@project-open.com
} {
    action
    note:array,optional
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

set note_list [array names note]
if {0 == [llength $note_list]} { ad_returnredirect $return_url }

switch $action {
    del_notes {
	foreach note_id $note_list {
	    db_string del_notes "select im_note__delete(:note_id)"
	}
    }
    default {
	ad_return_complaint 1 "<li>Unknown action: '$action'"
    }
}

ad_returnredirect $return_url

