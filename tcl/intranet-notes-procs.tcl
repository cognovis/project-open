# /packages/intranet-notes/tcl/intranet-notes-procs.tcl
#
# Copyright (C) 2003-2007 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_library {
    @author frank.bergmann@project-open.com
}


# ----------------------------------------------------------------------
# Constants
# ----------------------------------------------------------------------

ad_proc -public im_note_status_active {} { return 11400 }
ad_proc -public im_note_status_deleted {} { return 11402 }

ad_proc -public im_note_type_address {} { return 11500 }
ad_proc -public im_note_type_email {} { return 11502 }
ad_proc -public im_note_type_http {} { return 11504 }
ad_proc -public im_note_type_ftp {} { return 11506 }
ad_proc -public im_note_type_phone {} { return 11508 }
ad_proc -public im_note_type_fax {} { return 11510 }
ad_proc -public im_note_type_mobile {} { return 11512 }
ad_proc -public im_note_type_other {} { return 11514 }


# ----------------------------------------------------------------------
# Helper functions
# ----------------------------------------------------------------------

ad_proc -public im_note_format {
    -note_type_id:required
    -note:required
} {
    Formats a note, depending on the note's type
} {
    # The note may consist of several pieces, we only want to format
    # the first one of these pieces
    set note_pieces [split $note " "]
    set first_note [lindex $note_pieces 0]
    set rest_note [join [lrange $note_pieces 1 end] " "]

    set notes_edit_url [export_vars -base "/intranet-notes/new" {note_id return_url}]

    switch $note_type_id {
	11502 {
	    # Email
	    set note_formatted "<a href=\"mailto:$first_note\">$first_note</a> $rest_note"
	}
	11504 {
	    # Http
	    set note_formatted "<a href=\"$first_note\" target=\"_\">$first_note</a> $rest_note"
	}
	11506 {
	    # FTP
	    set note_formatted "<a href=\"$first_note\" target=\"_\">$first_note</a> $rest_note"
	}
	default {
	    set note_formatted "$first_note $rest_note"
	}
    }
    return $note_formatted
}


# ----------------------------------------------------------------------
# Components
# ---------------------------------------------------------------------

ad_proc -public im_notes_component {
    -object_id
} {
    Returns a HTML component to show all project related notes
} {
    set params [list \
		    [list base_url "/intranet-notes/"] \
		    [list object_id $object_id] \
		    [list return_url [im_url_with_query]] \
    ]

    set result [ad_parse_template -params $params "/packages/intranet-notes/www/notes-list-component"]
    return [string trim $result]
}
