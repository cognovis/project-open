ad_page_contract {
    Bulk update contacts

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2005-06-14
    @cvs-id $Id$
} {
    {object_id:integer,multiple ""}
    {person_ids ""}
    {organization_ids ""}
    {attribute_id ""}
    {return_url "./"}
} -validate {
    parties_submitted_p {
	if { [llength $object_id] == 0 && [llength $person_ids] == 0 && [llength $organization_ids] == 0 } {
	    ad_complain [_ intranet-contacts.lt_You_need_parties_to_bulk_update]
	}
    }
}

set title "[_ intranet-contacts.Bulk_Update]"
set user_id [ad_conn user_id]
set context [list $title]
set package_id [ad_conn package_id]
set recipients [list]
if { [exists_and_not_null object_id] } {
    foreach object_id $object_id {
        contact::require_visiblity -party_id $object_id
        if { [person::person_p -party_id $object_id] } {
            lappend person_ids $object_id
        } else {
            lappend organization_ids $object_id
        }
    }
}
set organization_count [llength $organization_ids]
set person_count [llength $person_ids]


set people [list]
foreach party_id $person_ids {
    lappend people "<a href=\"[contact::url -party_id $object_id]\">[person::name -person_id $object_id]</a>"
}
set people [join $people ", "]

set organizations [list]
foreach party_id $organization_ids {
    lappend organizations "<a href=\"[contact::url -party_id $object_id]\">[organizations::name -organization_id $object_id]</a>"
}
set organizations [join $organizations ", "]

set form_elements {
    person_ids:text(hidden),optional
    organization_ids:text(hidden),optional
    return_url:text(hidden)
}


if { $person_count == 0 } {
    lappend form_elements "people:text(hidden),optional"
} elseif { $person_count == 1 } {
    lappend form_elements [list people:text(inform),optional [list label [_ intranet-contacts.Person]]]
} else {
    lappend form_elements [list people:text(inform),optional [list label [_ intranet-contacts.People]]]
}

if { $organization_count == 0 } {
    lappend form_elements "organizations:text(hidden),optional"
} elseif { $organization_count == 1 } {
    lappend form_elements [list organizations:text(inform),optional [list label [_ intranet-contacts.Organization]]]
} else {
    lappend form_elements [list organizations:text(inform),optional [list label [_ intranet-contacts.Organizations]]]
}

if { $person_count > 0 && $organization_count > 0 } {
    set object_type "party"
} elseif { $person_count > 0 } {
    set object_type "person"
} elseif { $organization_count > 0 } {
    set object_type "organization"
}


if { [exists_and_not_null attribute_id] } {
    ams::attribute::get -attribute_id $attribute_id -array attr
    lappend form_elements [list attribute_id:integer(hidden)]
    lappend form_elements [ams::widget \
                               -widget $attr(widget) \
                               -request "ad_form_widget" \
                               -attribute_id $attr(attribute_id) \
                               -attribute_name $attr(attribute_name) \
                               -pretty_name $attr(pretty_name) \
                               -form_name "bulk_update" \
                               -optional_p "1"]
    set edit_buttons [list [list "[_ intranet-contacts.Bulk_Update_these_Contacts]" update]]
    lappend form_elements 
} else {

    set attribute_options [db_list_of_lists get_attributes {}]
    set attribute_options [ams::util::localize_and_sort_list_of_lists -list $attribute_options]

    set attribute_label [_ intranet-contacts.Attribute]
    set attribute_options [concat [list [list "" ""]] $attribute_options]
    lappend form_elements {attribute_id:integer(select) {label $attribute_label} {options $attribute_options}}
    set edit_buttons [list [list "[_ intranet-contacts.Next]" next]]

}


ad_form -action bulk-update \
    -name bulk_update \
    -cancel_label "[_ intranet-contacts.Cancel]" \
    -cancel_url $return_url \
    -edit_buttons $edit_buttons \
    -form $form_elements \
    -on_request {
    } -on_submit {
        if { [template::form get_button bulk_update] == "update" } {
            db_transaction {
            ams::attribute::get -attribute_id $attribute_id -array attr
            set value_id [ams::widget \
                              -widget $attr(widget) \
                              -request "form_save_value" \
                              -attribute_id $attr(attribute_id) \
                              -attribute_name $attr(attribute_name) \
                              -pretty_name $attr(pretty_name) \
                              -form_name "bulk_update" \
                              -optional_p "1"]
            set party_ids [concat $organization_ids $person_ids]
        
            foreach party_id $party_ids {
                set old_revision_id [contact::live_revision -party_id $party_id]
                set new_revision_id [contact::revision::new -party_id $party_id]
                if { [exists_and_not_null old_revision_id] } {
                    ams::object_copy -from $old_revision_id -to $new_revision_id
                }
                ams::attribute::value_save -object_id $new_revision_id -attribute_id $attribute_id -value_id $value_id
            }
            }
        }
    } -after_submit {
	contact::search::flush_results_counts
        if { [template::form get_button bulk_update] == "update" } {
	    ad_returnredirect -message [_ intranet-contacts.lt_your_bulk_update_was_successful] $return_url
            ad_script_abort
        }
    }


