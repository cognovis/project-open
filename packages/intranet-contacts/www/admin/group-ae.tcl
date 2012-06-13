ad_page_contract {


    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

} {
    {group_id:integer,optional}
    {object_type ""}
    {return_url "./"}
}
set user_id [auth::require_login]

set form_elements {
    group_id:key
    title:text(hidden),optional
    context:text(hidden),optional
    return_url:text(hidden),optional
}

if { [ad_form_new_p -key group_id] } {
    set parents "{{[_ intranet-contacts.lt_--_top_level_group_--]} {}} [contact::groups -expand "none" -output "ad_form" -privilege_required "admin"]"
    append form_elements {
        {parent:integer(select),optional {label "[_ intranet-contacts.Parent_Group]"} {options $parents}}
    }
} else {
    set parent_id [contact::group::parent -group_id $group_id]
    if { [exists_and_not_null parent_id] } {
        set parent [acs_object_name $parent_id]
        append form_elements {
            {parent:text(inform),optional {label "[_ intranet-contacts.Parent_Group]"}}
        }
    }
}

#append form_elements {
#    permitted_rels,text(checkbox) 
#}

append form_elements {
    {group_name:text(text) {label "[_ intranet-contacts.Group_Name]"}}
    join_policy:text(hidden)
    url:text(hidden),optional
    email:text(hidden),optional
}
ad_form -name group_ae -action group-ae -form $form_elements \
-new_request {
    set title "[_ intranet-contacts.Add_a_Group]"
    set context [list $title]
    set join_policy "open"
} -edit_request {

    db_1row select_group_info {
	select group_name, join_policy,
               url, email
          from groups,
               parties
         where groups.group_id = parties.party_id
           and groups.group_id = :group_id 
    }

    set title "[_ intranet-contacts.Edit_group_name]"
    set context [list [list groups "[_ intranet-contacts.Groups]"] $title]

} -validate {
} -new_data {

    db_transaction {
	contact::group::new \
	    -group_id $group_id \
	    -email $email \
	    -url $url \
	    -group_name $group_name \
	    -join_policy $join_policy \
	    -context_id ""

	if { [exists_and_not_null parent] } {
	    relation_add -member_state "approved" "composition_rel" $parent $group_id
	}
    }
    set message "[_ intranet-contacts.lt_Group_group_name_Crea]"

} -edit_data {

    db_dml update_group {
	update groups
           set group_name = :group_name,
               join_policy = :join_policy
         where group_id = :group_id
    }

    db_dml update_group_extras {
	update parties
           set email = :email,
               url = :url
         where party_id = :group_id
    }

    set message "[_ intranet-contacts.lt_Group_group_name_Upda]"

} -after_submit {

    # First flush our cache for the contact::groups as we change something here
    util_memoize_flush_regexp contact::groups_list_not_cached*
    
    ad_returnredirect -message ${message} ${return_url}
    ad_script_abort

}





ad_return_template
