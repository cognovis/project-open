# /www/intranet/allocations/note-edit-2.tcl
#

ad_page_contract {
    Writes edit to allocation note to db

    @author Mike Bryzek (mbryzek@arsdigita.com)
    @creation-date Jan 2000
    @cvs-id note-edit-2.tcl,v 3.2.6.4 2000/08/16 21:24:37 mbryzek Exp
} {
    allocation_note_start_block:notnull
    note:notnull,html
    start_block:optional
    end_block:optional
}


if { [catch { db_dml allocation_note_update "update im_start_blocks set note = :note 
                                             where start_block = :allocation_note_start_block" } error_msg] } {
    ad_return_error "Error updating database" $error_msg
    return
}

ad_returnredirect "index?[export_url_vars start_block end_block]"
