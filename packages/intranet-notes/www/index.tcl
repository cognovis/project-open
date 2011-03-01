# /packages/intranet-notes/www/index.tcl
#
# Copyright (C) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    @author frank.bergmann@project-open.com
} {
    { object_id:integer 0}
    { note_type_id:integer 0}
    { start_date "2000-01-01" }
    { end_date "2100-01-01" }
    { form_mode "edit" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]

set object_name [db_string object_name "select acs_object__name(:object_id)" -default [lang::message::lookup "" intranet-expenes.Unassigned "Unassigned"]]
if {0 == $object_id} { set object_name "All" }

set page_title "$object_name [lang::message::lookup "" intranet-notes.Notes "Notes"]"
set context_bar [im_context_bar $page_title]
set return_url [im_url_with_query]
set current_url [ns_conn url]
set org_note_type_id $note_type_id
set date_format "YYYY-MM-DD"

# ---------------------------------------------------------------
# Compose the List Template
# ---------------------------------------------------------------

# The columns to be shown in the NotesListPage
set elements_list {
    note_chk {
	label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('notes_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	display_template {
	    @note_lines.note_chk;noquote@
	}
    }
    note_type {
	label "[lang::message::lookup {} intranet-notes.Note_Type Type]"
	link_url_eval $object_url
    }
    note_formatted {
	display_template {
	    @note_lines.note_formatted;noquote@
	}
	label "[lang::message::lookup {} intranet-notes.Note_Note Note]"
    }
    creation_date {
	label "[lang::message::lookup {} intranet-notes.Note_Date Date]"
    }
    user_name {
	label "[lang::message::lookup {} intranet-notes.Note_CreationUser {Creation User}]"
	link_url_eval "/intranet/users/view?user_id=$creation_user"
    }
    object_name {
	label "[lang::message::lookup {} intranet-notes.Note_Object Object]"
	link_url_eval $object_url
    }
}

# The list of "bulk actions" to perform on the list of notes
set bulk_actions_list "[list]"
lappend bulk_actions_list [lang::message::lookup {} intranet-notes.Delete Delete] "notes-del" [lang::message::lookup {} intranet-notes.Remove_checked_items "Remove checked items"]

set list_id "notes_list"
template::list::create \
    -name $list_id \
    -multirow note_lines \
    -key note_id \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars { object_id } \
    -row_pretty_plural [lang::message::lookup {} intranet-notes.Notes_Items "Items"] \
    -elements $elements_list


# ---------------------------------------------------------------
# Determine the data to be shown
# ---------------------------------------------------------------

set where_clause ""
if {0 != $object_id && "" != $object_id} { append where_clause "\tand o.object_id = :object_id\n" }
if {0 != $note_type_id && "" != $note_type_id} { append where_clause "\tand n.note_type_id = :note_type_id\n" }

db_multirow -extend {note_chk return_url object_url note_formatted} note_lines notes_lines "
  select
        n.*,
        n.object_id as note_object_id,
        o.creation_date,
        o.creation_user,
        no.object_type,
        acs_object__name(n.object_id) as object_name,
        to_char(o.creation_date, :date_format) as creation_date,
        im_name_from_user_id(o.creation_user) as user_name,
        im_category_from_id(n.note_type_id) as note_type,
        bou.url as object_url
  from
        im_notes n,
        acs_objects o,
        acs_objects no
        left outer join (
                select  *
                from    im_biz_object_urls
                where   url_type = 'view'
        ) bou ON (no.object_type = bou.object_type)
  where
        n.note_id = o.object_id and
        n.object_id = no.object_id and
	o.creation_date > :start_date and
	o.creation_date <= :end_date
        $where_clause
" {
    set note_chk "<input type=\"checkbox\" name=\"note_id\" value=\"$note_id\" id=\"notes_list,$note_id\">"
    set return_url [im_url_with_query]
    set object_url [export_vars -base "/intranet-notes/new" {note_id}]
    set note_formatted [im_note_format -note_type_id $note_type_id -note $note]
}


# ---------------------------------------------------------------
# Filter for Notes
# ---------------------------------------------------------------

set left_navbar_html "
      <div class='filter-block'>
         <div class='filter-title'>
            [lang::message::lookup "" intranet-notes.Filter_Notes "Filter Notes"]
         </div>
	<form method=POST action='/intranet-notes/index'>
	<table>
	<tr>
	    <td class=form-label>[lang::message::lookup "" intranet-notes.Note_Type "Type"]</td>
	    <td class=form-widget>[im_category_select -translate_p 1 -package_key "intranet-notes" -include_empty_p 1  "Intranet Notes Type" note_type_id $org_note_type_id]</td>
	</tr>
	<tr>
	  <td class=form-label>Start Date</td>
	  <td class=form-widget>
	    <input type=textfield name=start_date value='$start_date'>
	  </td>
	</tr>
	<tr>
	  <td class=form-label>End Date</td>
	  <td class=form-widget>
	    <input type=textfield name=end_date value='$end_date'>
	  </td>
	</tr>
	<tr>
	    <td class=form-label></td>
	    <td class=form-widget><input type=submit></td>
	</tr>
	</table>
	</form>
      </div>
"
