ad_page_contract {

    Merge two contacts.

    @author Matthew Geddert (openacs@geddert.com)
    @creation-date 2006-01-26
} {
    {party_id:integer}
    {merge_party_id ""}
    {primary:optional}
} -validate {
    contact_exists -requires {party_id} {
	if { ![contact::exists_p -party_id $party_id] } {
	    ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	}
    }
    contact_is_not_me -requires {party_id} {
	if { $party_id == [ad_conn user_id] } {
	    ad_complain "[_ intranet-contacts.lt_You_cannot_merge_yourself]"
	}
    }
    merge_contact_is_not_me -requires {merge_party_id} {
	if { $merge_party_id == [ad_conn user_id] } {
	    ad_complain "[_ intranet-contacts.lt_You_cannot_merge_yourself]"
	}
    }
    merge_contact_exists -requires {merge_party_id} {
	if { [string is integer $merge_party_id] && [exists_and_not_null merge_party_id] } {
	    if { ![contact::exists_p -party_id $merge_party_id] } {
		ad_complain "[_ intranet-contacts.lt_The_contact_specified]"
	    }
	}
    }
    primary_is_valid -requires {primary} {
	if { [lsearch [list party_id merge_party_id] $primary] < 0 } {
	    error "primary was not valid"
	}
    }
}



permission::require_permission -object_id [ad_conn package_id] -privilege "admin"


set title [_ intranet-contacts.Merge_Contacts]
set context [list $title]


set party_type [contact::type -party_id $party_id]
set party_url [contact::url -party_id $party_id]
set party_link [contact::link -party_id $party_id]

if { [string is integer $merge_party_id] && [exists_and_not_null merge_party_id] } {

    set display_contacts "1"

    set merge_party_type [contact::type -party_id $merge_party_id]
    set merge_party_url [contact::url -party_id $merge_party_id]
    set merge_party_link [contact::link -party_id $merge_party_id]

    if { $party_type == "user" } {
	set party_last_login [db_string get_it { select last_visit from users where user_id = :party_id } -default {}]
	if { [exists_and_not_null party_last_login] } {
	    set party_last_login [lc_time_fmt $party_last_login "%x %X"]
	}
    }
    if { $merge_party_type == "user" } {
	set merge_party_last_login [db_string get_it { select last_visit from users where user_id = :merge_party_id } -default {}]
	if { [exists_and_not_null merge_party_last_login] } {
	    set merge_party_last_login [lc_time_fmt $merge_party_last_login "%x %X"]
	}
    }


} else {

    set display_contacts "0"



}

if { $party_type == "organization" } {
    set form_type "organizations"
} else {
    set form_type "persons"
}

ad_form -method get -name merge_contacts \
    -form [list [list merge_party_id:contact_search(contact_search) [list label "[_ intranet-contacts.Merge_with]"] [list search "$form_type"]]] \
    -on_submit {


	if { $party_id == $merge_party_id } {
	    template::element::set_error merge_contacts merge_party_id "[_ intranet-contacts.lt_You_no_merge_with_self]"
	    set display_contacts "0"
	}


    }



if { [exists_and_not_null primary] && [string is true $display_contacts] } {

    if { $primary == "merge_party_id" } {
	# we need to swap the merge_party_id and party_id
	set orig_party_id $party_id
        set party_id $merge_party_id
        set merge_party_id $orig_party_id

    }

    contacts::merge -from_party_id $merge_party_id -to_party_id $party_id

    util_user_message -message "[_ intranet-contacts.lt_The_contacts_were_merged]"
    ad_returnredirect [contact::url -party_id $party_id]
    ad_script_abort
    


}


ad_return_template








