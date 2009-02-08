ad_library {

    Support procs for attributes in the contacts package

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id$

}

namespace eval contacts::attribute {

    ad_proc -private create {
        {-widget_id:required}
        {-label:required}
        {-help_text ""}
        {-help_p ""}
        {-html ""}
        {-format ""}
    } {
        this code creates a new attributes
    } {
        set creation_user [ad_conn user_id]
        set creation_ip [ad_conn peeraddr]
        return [db_exec_plsql create_attribute {}]
    }


    ad_proc -private delete {
        {-attribute_id:required}
    } {
        this code deletes an attribute
    } {
        return [db_exec_plsql delete_attribute {} ]
    }


    ad_proc -public name {
        {-locale ""}
        attribute_id
    } {
        this code returns the name of an attribute
    } {

        if { ![exists_and_not_null locale] } {
            set locale [lang::conn::locale -site_wide]        
        }

        db_0or1row get_attribute_name {}

        if { ![exists_and_not_null name] } {
            set locale "en_US"
            db_0or1row get_view_name {}
        }
        
        return $name

    }

    ad_proc -public options_attribute { 
    } {
	Returns a list of only the attributes that have
	multiple choices of the format {pretty_name attribute_id}
    } {
	set options [db_list_of_lists get_option_attributes { }]
	lappend options [list "[_ intranet-contacts.Country]" "-1"]
	lappend options [list "[_ intranet-contacts.Relationship]" "-2"]
	return $options
    }

}


namespace eval contacts::attribute::value {

   ad_proc -private save {
        {-party_id:required}
        {-attribute_id:required}
        {-option_map_id ""}
        {-address_id ""}
        {-number_id ""}
        {-time ""}
        {-value ""}
        {-deleted_p "f"}
    } {
        this code creates a new attributes
    } {
        set creation_user [ad_conn user_id]
        set creation_ip [ad_conn peeraddr]
        return [db_exec_plsql attribute_value_save {}]
    }


}

namespace eval contacts::postal_address {


    ad_proc -private new {
        {-additional_text ""}
        {-country_code ""}
        {-delivery_address ""}
        {-municipality ""}
        {-postal_code ""}
        {-postal_type ""}
        {-region ""}
    } {
        this code saves a contact's address
    } {
        set creation_user [ad_conn user_id]
        set creation_ip [ad_conn peeraddr]

        return [db_exec_plsql postal_address_new {}]
    }

    ad_proc -public get {
        {-attribute_id}
	{-attribute_name ""}
	{-party_id:required}
        {-array:required}
        {-locale ""}
    } {
        get the info from addresses and store them in the array
        
        @return 1 if there successful, 0 otherwise.
        @return address
        @return municipality
        @return country
        @return country_code
        @return postal_code
        @return region
        @return town_line
    } {
        upvar $array row
	if {[exists_and_not_null attribute_id]} {
	    set where_clause "and aa.attribute_id = :attribute_id"
	} else {
	    set where_clause "and aa.attribute_name = :attribute_name"
	}
	set revision_id [contact::live_revision -party_id $party_id]
        set value [db_string select_address_info {} -default ""]
	if {[string eq "" $value]} {
	    return 0
	} else {
	    set mailing_address_list [ams::widget \
					  -widget postal_address \
					  -request "value_list_text" \
					  -value $value \
					 ]
            # This sets the address, muncipality, region, postal_code, country_code, country
	    array set row $mailing_address_list
	    set row(town_line) [template::util::address::town_line -municipality $row(municipality) -region $row(region) -postal_code $row(postal_code) -country_code $row(country_code)]
	    return 1
	}
    }

}




namespace eval contacts::telecom_number {

    ad_proc -private new {
        {-area_city_code ""}
        {-best_contact_time ""}
        {-extension ""}
        {-itu_id ""}
        {-location ""}
        {-national_number ""}
        {-sms_enabled_p ""}
        {-subscriber_number ""} 
    } {
        this code saves a contact's phone_number
    } {
        set creation_user [ad_conn user_id]
        set creation_ip [ad_conn peeraddr]

        return [db_exec_plsql telecom_number_new {}]
    }



    ad_proc -public get {
        {-number_id:required}
        {-array:required}
    } {
        get the variables from phone_numbers
    } {
        upvar $array row
        db_0or1row select_telecom_number_info {} -column_array row
    }

}


namespace eval contacts::date {

    ad_proc -private sqlify {
        {-date:required}
    } {
        this turns a form date into a timestamp postgresql likes
    } {
        set year [template::util::date::get_property year $date]
        set month [template::util::date::get_property month $date]
        set day [template::util::date::get_property day $date]
        set hours [template::util::date::get_property hours $date]
        set minutes [template::util::date::get_property minutes $date]
        
        set date "$year-$month-$day $hours:$minutes"
        if { $date == "-- :" } {
            set date ""
        }
	return $date
    }


}










