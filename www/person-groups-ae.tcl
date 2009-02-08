ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$


} {
    {person_id:integer,optional}
}

contact::require_visiblity -party_id $person_id

if { [exists_and_not_null person_id] } {
    set admin_user_url [acs_community_member_admin_url -user_id $person_id]
    set user_url [acs_community_member_url -user_id $person_id]
} else {
    set admin_user_url ""
    set user_url ""
}

set list_name "person_[ad_conn package_id]"
set object_type "person"
set package_key "contacts"

if { [ad_form_new_p -key person_id] } {
    set title "[_ intranet-contacts.Add_a_Person]"
    set mode "edit"
} else {
    set title [person::name -person_id $person_id]
    set mode "display"
}
set context [list $title]








# groups
ad_form -name groups_ae \
    -mode "display" \
    -has_edit "t" \
    -actions {
        {"[_ intranet-contacts.Add_to_Group]" "formbutton:edit"}
    } -form {
        {person_id:key}
    }

set package_id [ad_conn package_id]
set group_options [db_list_of_lists get_groups {
    select groups.group_name,
           groups.group_id,
           ( select count(distinct member_id) from group_member_map where group_member_map.group_id = groups.group_id ) as member_count
      from groups left join ( select group_id, owner_id, group_type, deprecated_p
                                from contact_groups
                               where package_id = :package_id ) contact_groups on (groups.group_id = contact_groups.group_id)
     where groups.group_id != '-1'
}]

set groups_available [db_list_of_lists get_groups {
    select groups.group_name,
           groups.group_id,
           ( select count(distinct member_id) from group_member_map where group_member_map.group_id = groups.group_id ) as member_count
      from groups left join ( select group_id, owner_id, group_type, deprecated_p
                                from contact_groups
                               where package_id = :package_id ) contact_groups on (groups.group_id = contact_groups.group_id)
     where groups.group_id != '-1'
}]
ad_form -extend -name groups_ae -form {
	{group_id:integer(checkbox),multiple {label "[_ intranet-contacts.Groups]"} {options $group_options}}
    } -edit_request {
	set group_id [db_list get_them { select distinct group_id from group_member_map where member_id = :person_id }]
        #ad_return_error $group_id $group_id
    } -on_submit {
    } -after_submit {
        ad_returnredirect -message "[_ intranet-contacts.lt_Group_Information_Sav]" [export_vars -base "person-ae" -url {person_id}]
    }



ad_return_template
