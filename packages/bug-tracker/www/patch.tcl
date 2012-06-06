ad_page_contract {
    Page for viewing and editing one patch.

    @author Peter Marklund (peter@collaboraid.biz)
    @date 2002-09-04
    @cvs-id $Id$
} {
    patch_number:integer,notnull
    mode:optional
    cancel_edit:optional    
    edit:optional
    accept:optional
    refuse:optional
    delete:optional    
    reopen:optional
    comment:optional
    download:optional
}

# Assert read permission (should this check be in the request processor?)
ad_require_permission [ad_conn package_id] read

# Initialize variables related to the request that we'll need
set package_id [ad_conn package_id]
set user_id [ad_conn user_id]
# Does the user have write privilege on the project?
set write_p [ad_permission_p $package_id write]

set submitter_id [bug_tracker::get_patch_submitter -patch_number $patch_number]

set user_is_submitter_p [expr { ![empty_string_p $submitter_id] && $user_id == $submitter_id }]
set write_or_submitter_p [expr $write_p || $user_is_submitter_p]
set project_name [bug_tracker::conn project_name]
set package_key [ad_conn package_key]
set view_patch_url "[ad_conn url]?[export_vars -url { patch_number }]"
set patch_status [db_string patch_status {}]

# Is this project using multiple versions?
set versions_p [bug_tracker::versions_p]

# Abort editing and return to view mode if the user hit cancel on the edit form
if { [exists_and_not_null cancel_edit] } {
    ad_returnredirect $view_patch_url
    ad_script_abort
}

# If the download link was clicked - return the text content of the patch
if { [exists_and_not_null download] } {
    
    set patch_content [db_string get_patch_content {}]

    doc_return 200 "text/plain" $patch_content
    ad_script_abort
}

# Initialize the page mode variable
# We are in view mode per default
if { ![info exists mode] } {
    if { [exists_and_not_null edit] } {
        set mode "edit"
    } elseif { [exists_and_not_null accept] } {        
        set mode "accept"
    } elseif { [exists_and_not_null refuse] } {
        set mode "refuse"
    } elseif { [exists_and_not_null delete] } {
        set mode "delete"
    } elseif { [exists_and_not_null reopen] } {
        set mode "reopen"
    } elseif { [exists_and_not_null comment] } {
        set mode "comment"
    } else {
        set mode "view"
    }
}

# Specify which fields in the form are editable
# And check that the user is permitted to take the chosen action
switch -- $mode {
    edit {
        if { ![expr $write_p || $user_is_submitter_p] } {
            ad_return_forbidden "Permission Denied" "You do not have permission to edit this patch. Only the submitter of the patch and users with write permission on the Bug Tracker project (package instance) may do so."
            ad_script_abort
        }

        set edit_fields {component_id summary generated_from_version apply_to_version}
    }
    accept {
        ad_require_permission $package_id write

        # The user should indicate which version the patch is applied to
        set edit_fields { applied_to_version }
    }
    refuse {
        ad_require_permission $package_id write

        set edit_fields {}
    }
    reopen {
        # User must have write permission to reopen a refused patch
        if { [string equal $patch_status "refused"] && !$write_p } {
            ad_return_forbidden "Permission Denied" "You do not have permission to reopen this refused patch, only users with write permission on the Bug Tracker package instance (project) may do so."
            ad_script_abort
        } elseif { [string equal $patch_status "deleted"] && !($user_is_submitter_p || $write_p)} {
            ad_return_forbidden "Permission Denied" "You do not have permission to reopen this deleted patch, only users with write permission on the Bug Tracker package instance (project) and the submitter of the patch may do so."
            ad_script_abort            
        } 

        set edit_fields {}
    }
    delete {
        # Only the submitter can delete a patch (admins can refuse it)
        if { !$user_is_submitter_p } {
            ad_return_forbidden "Permission Denied" "You do not have permission to cancel this patch - only the submitter of the patch may do so. If you are an administrator you can however refuse the patch."
            ad_script_abort
        }
        set edit_fields {}
    }
    comment {
        set edit_fields {}
    }
    view {
        set edit_fields {}
    }
}

foreach field $edit_fields {
    set field_editable_p($field) 1
}

if { ![string equal $mode "view"] } {
    ad_maybe_redirect_for_registration
}    

# XXX FIXME TODO editing a patch invokes filename::validate, which is too paranoid...

# Create the form
switch -- $mode {
      view {
          form create patch -has_submit 1 -cancel_url "[ad_conn url]?[export_vars -url { patch_number }]"
      } 
      default {
          form create patch -html { enctype multipart/form-data } -cancel_url "[ad_conn url]?[export_vars -url { patch_number }]"
      }
}

# Create the elements of the form
element create patch patch_number \
        -datatype integer \
        -widget   hidden

element create patch patch_number_i \
        -datatype integer \
        -widget   inform \
        -label    "Patch #"

element create patch component_id \
        -datatype text \
        -widget [ad_decode [info exists field_editable_p(component_id)] 1 select inform] \
        -label "Component" \
        -options [bug_tracker::components_get_options]

if { [string equal $mode "view"] } {
    element create patch fixes_bugs \
        -datatype text \
        -widget inform \
        -label "Fix for Bugs"
}

element create patch summary  \
        -datatype text \
        -widget [ad_decode [info exists field_editable_p(summary)] 1 text inform] \
        -label "Summary" \
        -html { size 50 }

element create patch submitter \
        -datatype text \
        -widget inform \
        -label "Submitted by"

element create patch status \
        -widget inform \
        -datatype text \
        -label "Status"

element create patch generated_from_version \
        -datatype text \
        -widget [ad_decode [info exists field_editable_p(generated_from_version)] 1 select inform] \
        -label "Generated from Version" \
        -options [bug_tracker::version_get_options -include_unknown] \
        -optional

element create patch apply_to_version \
        -datatype text \
        -widget [ad_decode [info exists field_editable_p(apply_to_version)] 1 select inform] \
        -label "Apply to Version" \
        -options [bug_tracker::version_get_options -include_undecided] \
        -optional

element create patch applied_to_version \
        -datatype text \
        -widget [ad_decode [info exists field_editable_p(applied_to_version)] 1 select inform] \
        -label "Applied to Version" \
        -options [bug_tracker::version_get_options -include_undecided] \
        -optional

switch -- $mode {
    edit - comment - accept - refuse - reopen - delete {
        element create patch description  \
                -datatype text \
                -widget comment \
                -label "Description" \
                -html { cols 60 rows 13 } \
                -optional
        
        element create patch desc_format \
                -datatype text \
                -widget select \
                -label "Description format" \
                -options { { "Plain" plain } { "HTML" html } { "Preformatted" pre } }

    }
    default {
        # View mode
        element create patch description \
                -datatype text \
                -widget inform \
                -label "Description"
    }
}

# In accept mode - give the user the ability to select associated
# bugs to be resolved
if { [string equal $mode "accept"] } {

    element create patch resolve_bugs \
            -datatype integer \
            -widget checkbox \
            -label "Resolve Bugs" \
            -options [bug_tracker::get_mapped_bugs -patch_number $patch_number -only_open_p 1] \
            -optional
}

if { [string equal $mode "edit"] } {
    # Edit mode - display the file upload widget for patch content
    element create patch patch_file \
          -datatype file \
          -widget file \
          -label "Patch file (leave blank to keep current file):" \
          -optional
} 

element create patch mode \
        -datatype text \
        -widget hidden \
        -value $mode

set page_title "Patch #$patch_number"
set context [list [list "patch-list" "Patches"] $page_title]

if { [form is_request patch] } {
    # The form was requested

    db_1row patch {} -column_array patch
    set patch(generated_from_version_name) [ad_decode $patch(generated_from_version) "" "Unknown" [bug_tracker::version_get_name -version_id $patch(generated_from_version)]]
    set patch(apply_to_version_name) [ad_decode $patch(apply_to_version) "" "Undecided" [bug_tracker::version_get_name -version_id $patch(apply_to_version)]]
    set patch(applied_to_version_name) [bug_tracker::version_get_name -version_id $patch(applied_to_version)]

    if {$user_id != 0} {
	set submitter_email_display "(<a href=\"mailto:$patch(submitter_email)\">$patch(submitter_email)</a>)"
    } else {
	set submitter_email_display ""
    }

    # When the user is taking an action that should change the status of the patch
    # - update the status (the new status will show up in the form)
    switch -- $mode {
        accept {
            set patch(status) "accepted"
        }
        refuse {
            set patch(status) "refused"
        }
        delete {
            set patch(status) "deleted"
        }
        reopen {
            set patch(status) "open"
        }
    }

    element set_properties patch patch_number \
            -value $patch(patch_number)
    element set_properties patch patch_number_i \
            -value $patch(patch_number)
    element set_properties patch component_id \
            -value [ad_decode [info exists field_editable_p(component_id)] 1 $patch(component_id) $patch(component_name)]
    if { [string equal $mode "view"] } {
        set map_new_bug_link [ad_decode $write_or_submitter_p "1" "\[ <a href=\"map-patch-to-bugs?patch_number=$patch(patch_number)\">Map to bugs</a> \]" ""]
        element set_properties patch fixes_bugs \
            -value "[bug_tracker::get_bug_links -patch_id $patch(patch_id) -patch_number $patch(patch_number) -write_or_submitter_p $write_or_submitter_p] <br>$map_new_bug_link"
    }
    element set_properties patch summary \
            -value [ad_decode [info exists field_editable_p(summary)] 1 $patch(summary) "<b>$patch(summary)</b>"]
    element set_properties patch submitter \
            -value "
    [acs_community_member_link -user_id $patch(submitter_user_id) \
            -label "$patch(submitter_first_names) $patch(submitter_last_name)"] $submitter_email_display"

    element set_properties patch status \
            -value [ad_decode [info exists field_editable_p(status)] 1 $patch(status) [bug_tracker::patch_status_pretty $patch(status)]]
    element set_properties patch generated_from_version \
            -value [ad_decode [info exists field_editable_p(generated_from_version)] 1 $patch(generated_from_version) $patch(generated_from_version_name)]
    element set_properties patch apply_to_version \
            -value [ad_decode [info exists field_editable_p(apply_to_version)] 1 $patch(apply_to_version) $patch(apply_to_version_name)]
    element set_properties patch applied_to_version \
            -value [ad_decode [info exists field_editable_p(applied_to_version)] 1 $patch(applied_to_version) $patch(applied_to_version_name)]

    set deleted_p [string equal $patch(status) deleted]

    if { ( [string equal $patch(status) open] && ![string equal $mode "accept"]) || [string equal $patch(status) "refused"] } {
        element set_properties patch applied_to_version -widget hidden
    }

    # Description/Actions/History
    set patch_id $patch(patch_id)
    set action_html ""
    db_foreach actions {} {
        set comment $comment_text
        append action_html "<b>$action_date_pretty [bug_tracker::patch_action_pretty $action] by $actor_first_names $actor_last_name</b>
        <blockquote>[bug_tracker::bug_convert_comment_to_html -comment $comment -format $comment_format]</blockquote>"
    }

    if { [string equal $mode "view"] } {
        element set_properties patch description -value $action_html
    } else {
        element set_properties patch description \
                -history $action_html \
                -header "$patch(now_pretty) [bug_tracker::patch_action_pretty $mode] by [bug_tracker::conn user_first_names] [bug_tracker::conn user_last_name]" \
                -value ""
    }    
    
    # Now that we have the patch summary we can make the page title more informative
    set page_title "Patch #$patch_number: $patch(summary)"

    # Create the buttons
    # If the user has submitted the patch he gets full write access on the patch
    set user_is_submitter_p [expr $patch(submitter_user_id) == [ad_conn user_id]]
    if { [string equal $mode "view"] } {
        set button_form_export_vars [export_vars -form { patch_number }]
        multirow create button name label

        if { $write_p || $user_is_submitter_p } {
            multirow append button "comment" "Comment"
            multirow append button "edit" "Edit"
        }

        switch -- $patch(status) {
            open {
                if { $write_p } {
                    multirow append button "accept" "Accept"
                    multirow append button "refuse" "Refuse"
                }

                # Only the submitter can cancel the patch
                if { $user_is_submitter_p } {
                    multirow append button "delete" "Delete"
                }
            }
            accepted {
                if { $write_p } {
                    multirow append button "reopen" "Reopen"
                }
            }
            refused {
                if { $write_p } {
                    multirow append button "reopen" "Reopen"    
                }
            }
            deleted {
                if { $write_p || $user_is_submitter_p } {
                    multirow append button "reopen" "Reopen"
                }
            }
        }
    }    

    # Check that the user is permitted to change the patch
    if { ![string equal $mode "view"] && !$write_p && !$user_is_submitter_p } {
        ns_log notice "$patch(submitter_user_id) doesn't have write on object $patch(patch_id)"
        ad_return_forbidden "Permission Denied" "<blockquote>
        You don't have permission to edit this patch.
        </blockquote>"
        ad_script_abort
    }    

    if { !$versions_p } {
        element set_properties patch generated_from_version -widget hidden
    }
}

if { [form is_valid patch] } {
    # A valid submit of the form

    set update_exprs [list]

    form get_values patch patch_number

    foreach column $edit_fields {
        set $column [element get_value patch $column]
        lappend update_exprs "$column = :$column"
    }

    switch -- $mode {
        accept {
            set status "accepted"
            lappend update_exprs "status = :status"
        }
        refuse {
            set status "refused"
            lappend update_exprs "status = :status"            
        }
        reopen {
            set status "open"
            lappend update_exprs "status = :status"
        }
        edit {
            # Get the contents of any new uploaded patch file
            set content [bug_tracker::get_uploaded_patch_file_content]

            if { ![empty_string_p $content] } {
                lappend update_exprs "content = :content"
            } 
        }
        delete {
            set status "deleted"
            lappend update_exprs "status = :status"            
        }
    }

    db_transaction {
        set patch_id [db_string patch_id {}]

        if { [llength $update_exprs] > 0 } {
            db_dml update_patch {}
        }

        set action_id [db_nextval "acs_object_id_seq"]

        foreach column { description desc_format } {
            set $column [element get_value patch $column]
        }

        set action $mode
        db_dml patch_action {}

        if { [string equal $mode "accept"] } {
            # Resolve any bugs that the user selected
            set resolve_bugs [element get_values patch resolve_bugs]

            foreach bug_number $resolve_bugs {

                set resolve_description "Fixed by <a href=\"patch?patch_number=$patch_number\">patch #$patch_number</a>"
                
                set workflow_id [bug_tracker::bug::get_instance_workflow_id]
                set bug_id [bug_tracker::get_bug_id -bug_number $bug_number -project_id $package_id]
                set case_id [workflow::case::get_id \
                                 -workflow_short_name "[bug_tracker::bug::workflow_short_name]" \
                                 -object_id $bug_id]
                set action_id [workflow::action::get_id -workflow_id $workflow_id -short_name "resolve"]
                set enabled_action_id [db_string get_enabled_action_id ""]
                         
                bug_tracker::bug::edit \
                    -bug_id $bug_id \
                    -enabled_action_id $enabled_action_id \
                    -description $resolve_description \
                    -desc_format "text/html" \
                    -array bug_row
            }
        }
    }

    ad_returnredirect $view_patch_url
    ad_script_abort
}

ad_return_template
