ad_page_contract {
    List and manage contacts.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$
} {
    {party_id:integer,notnull}
    {party_two:optional}
    {role_two ""}
    {buttonsearch:optional}
    {buttonme:optional}
    {query ""}
    {orderby "role,asc"}
} -validate {
    contact_one_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_first_contact_spe]"
	}
    }
    contact_two_exists -requires {party_two} {
	if { ![contact::exists_p -party_id $party_two] } {
	    ad_complain "[_ intranet-contacts.lt_The_second_contact_sp]"
	}
    }

}
contact::require_visiblity -party_id $party_id

set contact_type [contact::type -party_id $party_id]
if { $contact_type == "user" } {
    set contact_type "person"
}
set contact_name [contact::name -party_id $party_id]
set contact_url  [contact::url  -party_id $party_id]

# What groups should the person be added to

set group_ids ""
set package_url [ad_conn package_url]

set pretty_plural_list_name "contacts"
if { [exists_and_not_null role_two] } {
    set role_two_type [db_list get_valid_object_types {}]  
    if {$role_two_type eq "person"} {
	set role_two_types [list person user]
    } else {
	set role_two_types $role_two_type
    }
    set pretty_plural_list_name "[_ intranet-contacts.${role_two_type}]"
}



set name_order 0
set member_state "approved"
set format "normal"

set bulk_actions [list "[_ intranet-contacts.contact_rel_change]" "../relationship-bulk-move" "[_ intranet-contacts.contact_rel_change]"]
set admin_p [ad_permission_p [ad_conn package_id] admin]
#set default_group_id [contacts::default_group_id]
set title "Contacts"
set context {}
set package_url [ad_conn package_url]

if { [exists_and_not_null query] && [exists_and_not_null role_two] } {
    set primary_party $party_id
    
    template::list::create \
	-html {width 100%} \
	-name "contacts" \
	-multirow "contacts" \
	-row_pretty_plural "$pretty_plural_list_name found in search, please try again or add a new contact" \
	-checkbox_name checkbox \
	-selected_format ${format} \
	-orderby_name "order_search" \
	-key party_id \
	-elements {
	    type {
		    label {}
		    display_template {
		        <img src="/resources/contacts/Group16.gif" height="16" width="16" border="0"></img>
		    }
	    }
	    contact {
		    label {}
		    display_template {
		        <a href="@contacts.map_url@">@contacts.name@</a> <span style="padding-left: 1em; font-size: 80%;">\[<a href="<%=[contact::url -party_id ""]%>@contacts.object_id@">View</a>\]</span>
		    }
	    }
	} -filters {
	} -orderby {
	} -formats {
	    normal {
		label "[_ intranet-contacts.Table]"
		layout table
		row {
		    contact {}
		}
	    }
	}

    set search_id ""
    set original_party_id $party_id
    set deref_function [db_string deref "select name_method from acs_object_types where object_type = :role_two_type"]
    set object_deref "${deref_function}(object_id)"
    db_multirow -extend {map_url} -unclobber contacts contacts_select {} {
	set map_url [export_vars -base "${package_url}relationship-add" -url {{party_one $original_party_id} {party_two $object_id} {role_two $role_two}}]

	callback contact::contact_rels
    }

}


set rel_options [db_list_of_lists get_rels {}]
set rel_options [ams::util::localize_and_sort_list_of_lists -list $rel_options]

set rel_options [concat [list [list "[_ intranet-contacts.--select_one--]" ""]] $rel_options]

set form_elements {
    {role_two:text(select),optional {label "[_ intranet-contacts.Add]"} {options $rel_options}}
    {query:text(text),optional {label ""} {html {size 24}}}
    {search:text(submit) {label "[_ intranet-contacts.Search_Existing]"}}
}

if { [parameter::get -boolean -parameter "ForceSearchBeforeAdd" -default "0"] } {
    if { [exists_and_not_null query] && [exists_and_not_null role_two] } {
	lappend form_elements [list add:text(submit) [list label "[_ intranet-contacts.Add_New]"]]
    }
} else {
    lappend form_elements [list add:text(submit) [list label "[_ intranet-contacts.Add_New]"]]
}


ad_form \
    -name "search" \
    -method "GET" \
    -export {party_id} \
    -form $form_elements \
    -on_request {
    } -edit_request {
    } -on_refresh {
    } -on_submit {
	    if { ![exists_and_not_null role_two] } {
	        template::element set_error search role_two [_ intranet-contacts.Required]
	        break
	    }
	    if {[exists_and_not_null add]} {
	        ad_returnredirect [export_vars -base "${package_url}/add/${role_two_type}" -url {{object_id_two "$party_id"} role_two}]
	    }  
	    if { ![exists_and_not_null role_two] } {
	        template::element::set_error search role_two "[_ intranet-contacts.A_role_is_required]"
	    }
	    if { ![template::form::is_valid search] } {
	        break
	    }
    } -after_submit {
    }


template::list::create \
    -html {width 100%} \
    -name "relationships" \
    -multirow "relationships" \
    -key rel_id \
    -row_pretty_plural "[_ intranet-contacts.relationships]" \
    -selected_format "normal" \
    -bulk_actions $bulk_actions \
    -bulk_action_export_vars {party_id} \
    -elements {
        role {
            label "[_ intranet-contacts.Art_of_Relationship]"
            display_col role_singular
        }
        other_name {
            label "[_ intranet-contacts.Contact]"
            display_col other_name
            link_url_eval $contact_url
        }
        details {
            label "[_ intranet-contacts.Details]"
            display_col details;noquote
        }
        actions {
            label "[_ intranet-contacts.Actions]"
            display_template {
                <a href="@relationships.rel_delete_url@" class="button">[_ intranet-contacts.Delete]</a></if>
                <if @relationships.rel_add_edit_url@ not nil><a href="@relationships.rel_add_edit_url@" class="button">[_ intranet-contacts.Edit_Details]</a></if>
            }
        }
    } -filters {
        party_id {}
    } -orderby {
        other_name {
            label "[_ intranet-contacts.Contact]"
            orderby_asc  "im_name_from_id(other_party_id) asc, upper(role_singular) asc"
            orderby_desc "im_name_from_id(other_party_id) desc, upper(role_singular) asc"
        }
        role {
            label "[_ intranet-contacts.Role]"
            orderby_asc  "upper(role_singular) asc, im_name_from_id(other_party_id) asc"
            orderby_desc "upper(role_singular) desc, im_name_from_id(other_party_id) asc"
        }
        default_value role,asc
    } -formats {
	normal {
	    label "[_ intranet-contacts.Table]"
	    layout table
	    row {
		checkbox {}
                role {}
                other_name {}
                details {}
                actions {}
	    }
	}
    }


set package_id [ad_conn package_id]
set return_url "[ad_conn package_url]${party_id}/relationships"
db_multirow -unclobber -extend {contact_url rel_add_edit_url rel_delete_url details} relationships get_relationships "" {
    set contact_url [contact::url -party_id $other_party_id]

    set details ""
    set relation [::im::dynfield::Class get_instance_from_db -id $rel_id]
    set list_ids [$relation list_ids]
    append details "<dl class=\"attribute-values\">\n"
    foreach dynfield_id [::im::dynfield::Attribute dynfield_attributes -list_ids $list_ids -privilege "read"] {
        set element [im::dynfield::Element get_instance_from_db -id [lindex $dynfield_id 0] -list_id [lindex $dynfield_id 1]]
        set value [$relation value [$element attribute_name]]

        if {$value ne ""} {
            append details "<dt class=\"attribute-name\">[$element pretty_name]:</dt>\n"
            append details "<dd class=\"attribute-value\">${value}</dd>\n"
        }
    }
    append details "</dl>\n"

    set rel_delete_url [export_vars -base "${package_url}relationship-delete" -url {rel_id party_id return_url}]
    set role_singular [lang::util::localize $role_singular]
}
