# packages/contacts/tcl/contacts-populate.tcl

ad_library {

    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-05
    @arch-tag: 81868d37-99f5-48b1-8336-88e22c0e9001
}

namespace eval contacts::populate {}

ad_proc -private -callback contacts::populate::organization::customer_attributes {
    {-list_id:required}
} {
}

ad_proc -public contacts::populate::crm {
    {-package_id ""}
} {
    Procedure to install ams Attributes for a good CRM solution (at
								 least in our idea).

    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-05

    @return

    @error
} {
    ams::widgets_init

    if {[empty_string_p $package_id]} {
	set contacts_package_id [apm_package_id_from_key "contacts"]
    } else {
	set contacts_package_id $package_id
    }

    set registered_user_group_id [contacts::default_group -package_id $package_id]

    # Map the groups
    contact::group::map -group_id [group::get_id -group_name "Customers"]  -package_id $contacts_package_id
    contact::group::map -group_id [group::get_id -group_name "Employees"]  -package_id $contacts_package_id
    contact::group::map -group_id [group::get_id -group_name "Freelancers"]  -package_id $contacts_package_id
    contact::group::map -group_id [group::get_id -group_name "Project Managers"]  -package_id $contacts_package_id
    contact::group::map -group_id [group::get_id -group_name "Senior Managers"]  -package_id $contacts_package_id
    contact::group::map -group_id [group::get_id -group_name "Accounting"]  -package_id $contacts_package_id
    contact::group::map -group_id [group::get_id -group_name "Sales"]  -package_id $contacts_package_id
    contact::group::map -group_id [group::get_id -group_name "HR Managers"]  -package_id $contacts_package_id
    contact::group::map -group_id [group::get_id -group_name "Freelance Managers"]  -package_id $contacts_package_id

    # Hopefully all is now setup to map the groups accordingly.

    # We already have the registered users lists setup, so we only need
    # the list_id..  Actually we should never have to extend registered
    # users, but what the heck...

    # Person:: Registered Users

    set list_id [ams::list::get_list_id \
		     -package_key "contacts" \
		     -object_type "person" \
		     -list_name "${contacts_package_id}__${registered_user_group_id}"
		]

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "first_names" \
			  -datatype "string" \
			  -pretty_name "First Name(s)" \
			  -pretty_plural "First Name(s)" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "0" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "type_specific" \
			  -static_p "f" \
			  -if_does_not_exist]
    
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Vorname(n)"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Vornamen"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "textbox" \
	-dynamic_p "f"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "10" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "last_name" \
			  -datatype "string" \
			  -pretty_name "Last Name" \
			  -pretty_plural "Last Names" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "0" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "type_specific" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Nachname"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Nachnamen"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "textbox" \
	-dynamic_p "f"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "20" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "salutation" \
			  -datatype "string" \
			  -pretty_name "Salutation" \
			  -pretty_plural "Salutations" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Anrede"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Anreden"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "select" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "30" \
	-required_p "f" \
	-section_heading ""

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Dear Mr. "]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Sehr geehrter Herr"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Dear Mrs. "]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Sehr geehrte Frau"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Dear Ms. "]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Sehr geehrte Frau"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Dear "]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Sehr geehrter Herr / Frau"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Dear Professor"]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Sehr geehrter Professor"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Dear Dr."]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Sehr geehrter Dr."

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "person_title" \
			  -datatype "string" \
			  -pretty_name "Title" \
			  -pretty_plural "Titles" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Titel"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Titel"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "textbox" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "40" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "party" \
			  -attribute_name "email" \
			  -datatype "string" \
			  -pretty_name "Email Address" \
			  -pretty_plural "Email Addresses" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "0" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "type_specific" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "E-Mail Addresse"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "E-Mail Addresse"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "email" \
	-dynamic_p "f"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "50" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "directphoneno" \
			  -datatype "string" \
			  -pretty_name "Direct Phone No." \
			  -pretty_plural "Direct Phone Numbers" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Durchwahl"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Durchwahlen"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "telecom_number" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "60" \
	-required_p "f" \
	-section_heading ""


    # ORGA - REG

    set list_id [ams::list::get_list_id \
		     -package_key "contacts" \
		     -object_type "im_company" \
		     -list_name "${contacts_package_id}__${registered_user_group_id}"
		]

    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "name" \
			  -datatype "string" \
			  -pretty_name "Company Name" \
			  -pretty_plural "im_company Names" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Firmenname"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Firmennamen"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "textbox" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "10" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "short_name" \
			  -datatype "string" \
			  -pretty_name "Short Company Name" \
			  -pretty_plural "Short Company Names" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Firmenkürzel"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Firmenkürzel"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "textbox" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "15" \
	-required_p "f" \
	-section_heading ""


    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "company_name_ext" \
			  -datatype "string" \
			  -pretty_name "Company Name Extensions" \
			  -pretty_plural "Company Name Extensions" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Erweiterung Firmenname"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Erweiterungen Firmennamen"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "textbox" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "20" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "company_address" \
			  -datatype "string" \
			  -pretty_name "Company Address" \
			  -pretty_plural "Company Addresses" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Firmenanschrift"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Firmenanschriften"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "postal_address" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "30" \
	-required_p "f" \
	-section_heading ""

    # E-Mail is a special party attribute. Therefore we just grab the attribute number here.
    set attribute_id [attribute::id -object_type "party" -attribute_name "email"]

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "email" \
	-dynamic_p "f"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "34" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "company_url" \
			  -datatype "url" \
			  -pretty_name "Company URL" \
			  -pretty_plural "Company URLs" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Webseite"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Webseiten"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "url" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "40" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "company_phone" \
			  -datatype "string" \
			  -pretty_name "Company Phone No." \
			  -pretty_plural "Company Phone Numbers" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Telefonnummer (Firma)"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Telefonnummern (Firma)"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "telecom_number" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "50" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "company_fax" \
			  -datatype "string" \
			  -pretty_name "Company Fax No." \
			  -pretty_plural "Company Fax Numbers" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Faxnummer (Firma)"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Faxnummern (Firma)"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "telecom_number" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "55" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "industrysector" \
			  -datatype "string" \
			  -pretty_name "Industry Sector" \
			  -pretty_plural "Industry Sectors" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Branche"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Branchen"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "select" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "60" \
	-required_p "f" \
	-section_heading ""

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Agency - Full Service"]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Full Service Agentur"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Agency - Special"]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Spezialagentur"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Agency - PR"]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "PR-Agentur"


    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "collaboration_notes" \
			  -datatype "text" \
			  -pretty_name "Notes on Collaboration" \
			  -pretty_plural "Notes on Collaboration" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Notizen zur Zusammenarbeit"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Notizen zur Zusammenarbeit"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "textarea" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "70" \
	-required_p "f" \
	-section_heading ""


    #     Organization - Customer

    set list_id [ams::list::new \
		     -package_key "contacts" \
		     -object_type "im_company" \
		     -list_name "${contacts_package_id}__${customers_id}" \
		     -pretty_name "im_company - Customer" \
		     -description "" \
		     -description_mime_type ""]

    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "clienttype" \
			  -datatype "string" \
			  -pretty_name "Type of Customer" \
			  -pretty_plural "Types of Customer" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Kundentyp"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Kundentypen"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "select" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "10" \
	-required_p "f" \
	-section_heading ""

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "VIP Customer"]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "VIP Kunde"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Good Customer"]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Guter Kunde"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Normal Customer"]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Normaler Kunde"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Sporadic Customer"]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Gelegentlicher Kunde"

    set option_id [ams::option::new \
		       -attribute_id $attribute_id \
		       -option "Follow-up Customer"]

    lang::message::register -update_sync de_DE acs-translations "ams_option_${option_id}" "Follow-Up Kunde"

    set attribute_id [attribute::new \
			  -object_type "im_company" \
			  -attribute_name "customer_since" \
			  -datatype "date" \
			  -pretty_name "Customer Since" \
			  -pretty_plural "Customers Since" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Kunde seit"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Kunde seit"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "date" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "20" \
	-required_p "f" \
	-section_heading ""

    callback contacts::populate::organization::customer_attributes -list_id $list_id

    set attribute_id [attribute::new \
              -object_type "im_company" \
              -attribute_name "invoice_specialities" \
              -datatype "text" \
              -pretty_name "Invoice Specialities" \
              -pretty_plural "Invoice Specialities" \
              -table_name "" \
              -column_name "" \
              -default_value "" \
              -min_n_values "1" \
              -max_n_values "1" \
              -sort_order "1" \
              -storage "generic" \
              -static_p "f" \
			  -if_does_not_exist]

ams::attribute::new \
              -attribute_id $attribute_id \
              -widget "textarea" \
              -dynamic_p "t"

ams::list::attribute::map \
              -list_id $list_id \
              -attribute_id $attribute_id \
              -sort_order "111" \
              -required_p "f" \
              -section_heading ""
    
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Rechnungsbesonderheiten"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Rechnungsbesonderheiten"

    # Person - Customer

    set list_id [ams::list::new \
		     -package_key "contacts" \
		     -object_type "person" \
		     -list_name "${contacts_package_id}__${customers_id}" \
		     -pretty_name "Person - Customer" \
		     -description "" \
		     -description_mime_type ""]


    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "department" \
			  -datatype "string" \
			  -pretty_name "Department" \
			  -pretty_plural "Departments" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Abteilung"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Abteilungen"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "textbox" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "10" \
	-required_p "f" \
	-section_heading ""

    ams::list::attribute::map \
	-list_id $leads_list_id \
	-attribute_id $attribute_id \
	-sort_order "10" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "jobtitle" \
			  -datatype "string" \
			  -pretty_name "Job Title" \
			  -pretty_plural "Job Titles" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Position"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Positionen"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "textbox" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "20" \
	-required_p "f" \
	-section_heading ""

    ams::list::attribute::map \
	-list_id $leads_list_id \
	-attribute_id $attribute_id \
	-sort_order "20" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "telephone_other" \
			  -datatype "string" \
			  -pretty_name "Other Tel. No." \
			  -pretty_plural "Other Tel. Numbers" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Andere Telefonnummer"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Andere Telefonnummern"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "telecom_number" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "40" \
	-required_p "f" \
	-section_heading ""

    ams::list::attribute::map \
	-list_id $leads_list_id \
	-attribute_id $attribute_id \
	-sort_order "40" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "directfaxno" \
			  -datatype "string" \
			  -pretty_name "Direct Fax No." \
			  -pretty_plural "Direct Fax Numbers" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Direkte Faxnummer"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Direkte Faxnummern"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "telecom_number" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "50" \
	-required_p "f" \
	-section_heading ""

    ams::list::attribute::map \
	-list_id $leads_list_id \
	-attribute_id $attribute_id \
	-sort_order "50" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "mobile_phone" \
			  -datatype "string" \
			  -pretty_name "Mobile Phone No." \
			  -pretty_plural "Mobile Phones" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Mobilfunk Nummer"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Mobilfunk Nummer"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "telecom_number" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "60" \
	-required_p "f" \
	-section_heading ""

    ams::list::attribute::map \
	-list_id $leads_list_id \
	-attribute_id $attribute_id \
	-sort_order "60" \
	-required_p "f" \
	-section_heading ""

    set attribute_id [attribute::new \
			  -object_type "person" \
			  -attribute_name "delivery_address" \
			  -datatype "string" \
			  -pretty_name "Delivery Address" \
			  -pretty_plural "Delivery Addresses" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Lieferanschrift"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Lieferanschrift"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "postal_address" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "80" \
	-required_p "f" \
	-section_heading ""

    # Register Relationships

    rel_types::create_role -role "parent_company" -pretty_name "Parent Company" -pretty_plural "Parent Companies"
    lang::message::register -update_sync de_DE acs-translations "role_parent_company" "Mutterfirma"

    rel_types::create_role -role "subsidiary" -pretty_name "Subsidiary" -pretty_plural "Subsidiaries"
    lang::message::register -update_sync de_DE acs-translations "role_subsidiary" "Tochterfirma"

    rel_types::new -table_name "contact_rels_subsidiary" -create_table_p "t" -supertype "contact_rel" -role_one "parent_company" -role_two "subsidiary" \
	"contact_rels_subsidiary" \
	"Contact Rel Subsidiary" \
	"Contact Rels Subsidiary" \
	"im_company" \
	"0" \
	"" \
	"im_company" \
	"0" \
	""

    # Contact Rels Subsidiary

    set list_id [ams::list::new \
		     -package_key "contacts" \
		     -object_type "contact_rels_subsidiary" \
		     -list_name "$contacts_package_id" \
		     -pretty_name "Contact Rels Subsidiary" \
		     -description "" \
		     -description_mime_type ""]

    set attribute_id [attribute::new \
			  -object_type "contact_rels_subsidiary" \
			  -attribute_name "shares" \
			  -datatype "integer" \
			  -pretty_name "Shares" \
			  -pretty_plural "Shares" \
			  -table_name "" \
			  -column_name "" \
			  -default_value "" \
			  -min_n_values "1" \
			  -max_n_values "1" \
			  -sort_order "1" \
			  -storage "generic" \
			  -static_p "f" \
			  -if_does_not_exist]

    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_name" "Anteil"
    lang::message::register -update_sync de_DE acs-translations "ams_attribute_${attribute_id}_pretty_plural" "Anteile"

    ams::attribute::new \
	-attribute_id $attribute_id \
	-widget "integer" \
	-dynamic_p "t"

    ams::list::attribute::map \
	-list_id $list_id \
	-attribute_id $attribute_id \
	-sort_order "1" \
	-required_p "f" \
	-section_heading ""
}
