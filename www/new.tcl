# /packages/intranet-notes/www/new.tcl
#
# Copyright (C) 2003-2006 ]project-open[
# all@devcon.project-open.com
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
    project_id:integer
    {note ""}
    {return_url "/intranet-notes/index"}
    {form_mode "edit"}
}

if {[info exists var_name]} { ad_return_complaint 1 "var_name = $var_name" }

set user_id [ad_maybe_redirect_for_registration]
set page_title [_ intranet-notes.Notes_creation]
set context_bar [im_context_bar $page_title]

set project_options [im_project_options]

set note_type_options [db_list_of_lists note_type_options "
	select	note_type, note_type_id
	from	im_note_types
	order by note_type_id
"]

set form_id "form"

ad_form \
    -name $form_id \
    -mode $form_mode \
    -export "project_id return_url" \
    -form {
	note_id:key
	{note_type_id:text(select) {label "[_ intranet-core.Type]"} {options $note_type_options} }
	{note:text(textarea) {label Note} {html {cols 40} {rows 8} }}
    }

ad_form -extend -name $form_id \
    -select_query {
	select	*
	from	im_notes
	where	note_id = :note_id
    } -new_data {
	db_exec_plsql create_note "
		SELECT im_note__new(
			:note_id,
			'im_note',
			now(),
			:user_id,
			'[ad_conn peeraddr]',
			null,
			:note,
			:project_id,
			:note_type_id,
			[im_note_status_active]
		)
        "
    } -edit_data {
	db_dml edit_note "
		update im_notes
		set note = :note
		where note_id = :note_id
	"
    } -after_submit {
	ad_returnredirect $return_url
	ad_script_abort
    }


