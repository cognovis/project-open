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
    { object_id 0}
    { form_mode "edit" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

# User id already verified by filters
set user_id [ad_maybe_redirect_for_registration]
set current_user_id $user_id
set page_focus "im_header_form.keywords"
set user_admin_p [im_is_user_site_wide_or_intranet_admin $current_user_id]
set date_format "YYYY-MM-DD"

set object_name [db_string object_name "select acs_object__name(:object_id)" -default [lang::message::lookup "" intranet-expenes.Unassigned "Unassigned"]]
if {0 == $object_id} { set object_name "All" }

set page_title "$object_name [lang::message::lookup "" intranet-notes.Notes "Notes"]"
if {[im_permission $user_id view_projects_all]} {
    set context_bar [im_context_bar [list /intranet/projects/ "[_ intranet-core.Projects]"] $page_title]
} else {
    set context_bar [im_context_bar $page_title]
}

set return_url [im_url_with_query]
set current_url [ns_conn url]


# ---------------------------------------------------------------
# Admin Links
# ---------------------------------------------------------------

set add_expense_p [im_permission $user_id "add_expense"]
# ToDo: Add Security
set add_expense_p 1


set admin_links ""
if {$add_expense_p} {
    append admin_links " <li><a href=\"new?[export_url_vars object_id return_url]\">[lang::message::lookup {} intranet-notes.Add_a_new_Note "Add a new Note"]</a>\n"
}

set bulk_actions_list "[list]"
set delete_expense_p 1 
if {$delete_expense_p} {
    lappend bulk_actions_list [lang::message::lookup {} intranet-notes.Delete Delete] "notes-del" [lang::message::lookup {} intranet-notes.Remove_checked_items "Remove checked items"]
}

# ---------------------------------------------------------------
# Expenses info
# ---------------------------------------------------------------

set export_var_list [list]

set list_id "notes_list"
template::list::create \
    -name $list_id \
    -multirow note_lines \
    -key note_id \
    -has_checkboxes \
    -bulk_actions $bulk_actions_list \
    -bulk_action_export_vars  {
	object_id
    } \
    -row_pretty_plural "[_ intranet-notes.Notes_Items]" \
    -elements {
	note_chk {
	    label "<input type=\"checkbox\" 
                          name=\"_dummy\" 
                          onclick=\"acs_ListCheckAll('notes_list', this.checked)\" 
                          title=\"Check/uncheck all rows\">"
	    display_template {
		@note_lines.note_chk;noquote@
	    }
	}
	creation_date {
	    label "[lang::message::lookup {} intranet-notes.Note_Date Date]"
	    link_url_eval {[export_vars -base new {note_id object_id return_url}]}
	}
        user_name {
	    label "[lang::message::lookup {} intranet-notes.Note_CreationUser {Creation User}]"
	    link_url_eval "/intranet/users/view?user_id=$creation_user"
	}
	note_type {
            label "[lang::message::lookup {} intranet-notes.Note_Type Type]"
        }
        object_name {
            label "[lang::message::lookup {} intranet-notes.Note_Object Object]"
            link_url_eval $object_url
        }
    }


# Add DynFields

set dynfield_sql "
        select  aa.attribute_name,
                aa.pretty_name,
                w.deref_plpgsql_function
        from
                im_dynfield_attributes a,
                im_dynfield_widgets w,
                acs_attributes aa
        where
                a.widget_name = w.widget_name
                and a.acs_attribute_id = aa.attribute_id
                and aa.object_type = 'im_note'
"

set dynfield_extra_select ""
db_foreach dynfields $dynfield_sql {

    # Add a new field to the list definition
    lappend elements_list $attribute_name
    lappend elements_list {
        label $pretty_name
    }

    # Extract/select out the DynField from the
    # object and "dereference" the object (convert
    # an integer to a string)
    append dynfield_extra_select ", $deref_plpgsql_function\($attribute_name) as $attribute_name\n"
}

# Append the final "Note" field
lappend elements_list note
lappend elements_list {
    label "[lang::message::lookup {} intranet-notes.Note_Note Note]"
}


set export_var_list [list]
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

set project_where ""
if {0 != $object_id} {
    set project_where "\tand c.object_id = :object_id\n"
}

if {0 == $object_id} { 
    set project_where "\tand n.object_id is null\n" 
} else {
    set project_where "\tand n.object_id = :object_id\n" 
}

db_multirow -extend {note_chk return_url} note_lines notes_lines "
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
        $dynfield_extra_select
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
        n.object_id = no.object_id
        $project_where
" {
    set note_chk "<input type=\"checkbox\"
                                name=\"note_id\"
                                value=\"$note_id\"
                                id=\"notes_list,$note_id\">"
    set return_url [im_url_with_query]

    append object_url "$note_object_id"
    if {0 == $object_id} {
        set object_name "-"
        set object_url ""
    }
}

# ---------------------------------------------------------------
# Project Menu
# ---------------------------------------------------------------

# Setup the subnavbar
set bind_vars [ns_set create]
ns_set put $bind_vars object_id $object_id
set project_menu_id [db_string parent_menu "select menu_id from im_menus where label='project'" -default 0]
set project_menu [im_sub_navbar $project_menu_id $bind_vars "" "pagedesriptionbar" "project_expenses"]

