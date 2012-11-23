# /packages/intranet-audit/www/view.tcl

ad_page_contract {
    Shows a single audit record in more details
    @author frank.bergmann@project-open.com
    @creation-date August 2011
} {
    audit_id
    return_url
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set current_user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-audit.Audit_Details]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

set exists_p [db_0or1row object_info "
	select	o.*,
		ot.*,
		a.*,
		last_a.audit_value as last_audit_value,
		im_category_from_id(a.audit_object_status_id) as audit_object_status,
		im_name_from_user_id(a.audit_user_id) as audit_user_name,
		to_char(a.audit_date, 'YYYY-MM-DD') as audit_date_pretty
	from	im_audits a
		LEFT OUTER JOIN im_audits last_a ON (a.audit_last_id = last_a.audit_id),
		acs_objects o,
		acs_object_types ot
	where	a.audit_object_id = o.object_id and
		ot.object_type = o.object_type and
		a.audit_id = :audit_id
"]

if {!$exists_p} {
    ad_return_complaint 1 "Didn't find audit record \#$audit_id."
    ad_script_abort
}

set perm_cmd "${object_type}_permissions \$current_user_id \$audit_object_id view read write admin"
eval $perm_cmd
if {!$read} {
    ad_return_complaint "Insufficient Privileges" "
    <li>You don't have sufficient privileges to see this page."    
}

set audit_user_url [export_vars -base "/intranet/users/view" {{user_id $audit_user_id}}]
set audit_host_url [export_vars -base "/intranet/admin/host" {{ip $audit_ip}}]


# ---------------------------------------------------------------
# Write the last_audit values into a hash
# ---------------------------------------------------------------

foreach field [split $last_audit_value "\n"] {
    set attribute_name [lindex $field 0]
    set attribute_value [lrange $field 1 end]

    if {[regexp {^acs_rel} $attribute_name match]} { 
	catch {
	    set attribute_value [im_audit_format_rel_value -object_id $object_id -value $attribute_value]
	}
    }
    set last_audit_hash($attribute_name) $attribute_value
}


# ---------------------------------------------------------------
# Format changes
# ---------------------------------------------------------------

array set pretty_name_hash [im_audit_attribute_pretty_names -object_type $object_type]
array set ignore_hash [im_audit_attribute_ignore -object_type $object_type]
array set deref_hash [im_audit_attribute_deref -object_type $object_type]

# Get the list of modified fields
set field_list [split $audit_diff "\n"]
# set field_list [split $audit_value "\n"]

set changed_fields_html ""
foreach field $field_list {
    set attribute_name [lindex $field 0]
    set attribute_value [lrange $field 1 end]

    if {[regexp {^acs_rel} $attribute_name match]} { 
	catch {
	    set attribute_value [im_audit_format_rel_value -object_id $object_id -value $attribute_value]
	}
    }

    set attribute_last_value ""
    if {[info exists last_audit_hash($attribute_name)]} {
        set attribute_last_value $last_audit_hash($attribute_name)
    }
    set pretty_name $attribute_name
    if {[info exists pretty_name_hash($attribute_name)]} { set pretty_name $pretty_name_hash($attribute_name)}

    append changed_fields_html "
		<tr>
		<td>$pretty_name</td>
		<td>$attribute_value</td>
		<td>$attribute_last_value</td>
		</tr>
    "
}

