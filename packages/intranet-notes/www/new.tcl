# /packages/intranet-notes/www/new.tcl
#
# Copyright (C) 2003-2006 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    New page is basic...
    @author all@devcon.project-open.com
} {
    note_id:integer,optional
    {object_id:integer "" }
    {note ""}
    {return_url "/intranet-notes/index"}
    {form_mode "edit"}
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title [_ intranet-notes.Notes_creation]
if {[info exists note_id]} { set page_title [lang::message::lookup "" intranet-notes.Note Note] }
set context_bar [im_context_bar $page_title]

# We can determine the ID of the "container object" from the
# note data, if the note_id is there (viewing an existing note).
if {[info exists note_id] && "" == $object_id} {
    set object_id [db_string oid "select object_id from im_notes where note_id = :note_id" -default ""]
}


# ---------------------------------------------------------------
# Create the Form
# ---------------------------------------------------------------

set form_id "form"
ad_form \
    -name $form_id \
    -mode $form_mode \
    -export "object_id return_url" \
    -form {
	note_id:key
	{note_type_id:text(im_category_tree) {label "[lang::message::lookup {} intranet-notes.Notes_Type Type]"} {custom {category_type "Intranet Notes Type" translate_p 1 package_key intranet-notes include_empty_p 0}} }
	{note:text(textarea) {label "[lang::message::lookup {} intranet-notes.Notes_Note Note]"} {html {cols 40} {rows 8} }}
    }

# Add DynFields to the form
set my_note_id 0
if {[info exists note_id]} { set my_note_id $note_id }
im_dynfield::append_attributes_to_form \
    -object_type "im_note" \
    -form_id $form_id \
    -object_id $my_note_id



# ---------------------------------------------------------------
# Define Form Actions
# ---------------------------------------------------------------

ad_form -extend -name $form_id \
    -select_query {

	select	*
	from	im_notes
	where	note_id = :note_id

    } -new_data {

        set note [string trim $note]
        set duplicate_note_sql "
                select  count(*)
                from    im_notes
                where   object_id = :object_id and note = :note
        "
        if {[db_string dup $duplicate_note_sql]} {
            ad_return_complaint 1 "<b>[lang::message::lookup "" intranet-notes.Duplicate_note "Duplicate note"]</b>:<br>
            [lang::message::lookup "" intranet-notes.Duplicate_note_msg "
	    	There is already the same note available for the specified object.
	    "]"
	    ad_script_abort
        }

	set note_id [db_exec_plsql create_note "
		SELECT im_note__new(
			:note_id,
			'im_note',
			now(),
			:user_id,
			'[ad_conn peeraddr]',
			null,
			:note,
			:object_id,
			:note_type_id,
			[im_note_status_active]
		)
        "]

        im_dynfield::attribute_store \
            -object_type "im_note" \
            -object_id $note_id \
            -form_id $form_id

    } -edit_data {

        set note [string trim $note]
	db_dml edit_note "
		update im_notes
		set note = :note
		where note_id = :note_id
	"
        im_dynfield::attribute_store \
            -object_type "im_note" \
            -object_id $note_id \
            -form_id $form_id

    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }


