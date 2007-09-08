# /packages/intranet-notes/www/action.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Purpose: Takes commands from the /intranet/projects/view
    page and saves changes, deletes tasks and scans for Trados
    files.

    @param return_url the url to return to
    @param note_id

    @author frank.bergmann@project-open.com
} {
    action
    note:array,optional
    return_url
}

set user_id [ad_maybe_redirect_for_registration]

set note_list [array names note]
if {0 == [llength $note_list]} { ad_returnredirect $return_url }

# Convert the list of selected notes into a "note_id in (1,2,3,4...)" clause
#
set note_in_clause "and note_id in ("
lappend note_list 0
append note_in_clause [join $note_list ", "]
append note_in_clause ")\n"

ns_log Notice "note-action: action=$action, note_in_clause=$note_in_clause"

switch $action {

    del_notes {
	set sql "
		delete from im_notes
		where	1=1
			$note_in_clause"
	db_dml del_notes $sql
    }

    default {
	ad_return_complaint 1 "<li>Unknown action: '$action'"
    }
}

ad_returnredirect $return_url

