ad_library {

    Contacts install library
    Procedures that deal with installing, instantiating, mounting.

    @creation-date 2005-05-26
    @author Timo Hentschel (timo@timohentschel.de)
    @cvs-id $Id$
}

namespace eval contacts::install {}
namespace eval ::im {}
namespace eval ::im::contacts {}

ad_proc -public contacts::install::package_install {
} {
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-04

    @return

    @error
} {

    set person_list [list [list home_phone "Home Phone" 4 textbox_medium ""] \
        [list work_phone "Work Phone" 5 textbox_medium ""] \
        [list cell_phone "Cell Phone" 6 textbox_medium ""] \
        [list pager "Pager" 7 textbox_medium ""] \
        [list fax "Fax" 8 textbox_medium ""] \
        [list aim_screen_name "AIM Screenname" 9 textbox_medium ""] \
        [list msn_screen_name "MSN Screenname" 10 textbox_medium ""] \
        [list icq_number "ICQ Number" 11 textbox_medium ""] \
        [list ha_line1 "Home Address Line 1" 12 textbox_medium ""] \
        [list ha_line2 "Home Address Line 2" 13 textbox_medium ""] \
        [list ha_city "Home Address City" 14 textbox_medium ""] \
        [list ha_state "Home Address State" 15 textbox_medium ""] \
        [list ha_postal_code "Home Address Postal Code" 16 textbox_medium ""] \
        [list ha_country_code "Home Address Country Code" 17 country_codes ""] \
        [list wa_line1 "Work Address Line 1" 18 textbox_medium ""] \
        [list wa_line2 "Work Address Line 2" 19 textbox_medium ""] \
        [list wa_city "Work Address City" 20 textbox_medium ""] \
        [list wa_state "Work Address State" 21 textbox_medium ""] \
        [list wa_postal_code "Work Address Postal Code" 22 textbox_medium ""] \
        [list wa_country_code "Work Address Country Code" 23 country_codes ""] \
        [list note "Note" 24 textarea_small_nospell ""] \
        [list current_information "Current Information" 25 textarea_small_nospell ""]]
    
    set im_company_list [list [list company_name "#intranet-core.Company_Name#" 1 textbox_large "1"] \
        [list company_path "#intranet-core.Company_Short_Name#" 2 textbox_medium "1"] \
        [list referral_source "#intranet-core.Referral_Source#" 3 textbox_large ""] \
        [list company_status_id "#intranet-core.Company_Status#" 4 category_company_status ""] \
        [list company_type_id "#intranet-core.Company_Type#" 5 category_company_type ""] \
        [list manager_id "#intranet-core.Key_Account#" 6 employees ""] \
        [list site_concept "#intranet-core.Web_Site#" 15 textbox_large ""] \
        [list vat_number "#intranet-core.VAT_Number#" 16 textbox_large ""] \
        [list annual_revenue_id "#intranet-core.Annual_Revenue#" 17 annual_revenue ""] \
        [list note "#intranet-core.Note#" 18 textarea_small_nospell ""]]
    
    set im_office_list [list [list office_name "#intranet-core.Office_Name#" 1 textbox_large "1"] \
			 [list office_path "#intranet-core.lt_Office_Directory_Path#" 2 textbox_medium "1"] \
			 [list office_status_id "#intranet-core.Office_Status#" 3 category_office_status ""] \
			 [list office_type_id "#intranet-core.Office_Type#" 4 category_office_type ""] \
			 [list phone "#intranet-core.Phone#" 5 textbox_small ""] \
			 [list fax "#intranet-core.Fax#" 6 textbox_small ""] \
			 [list address_line1 "#intranet-core.Address_1#" 7 textbox_medium ""] \
			 [list address_line2 "#intranet-core.Address_2#" 8 textbox_medium ""] \
			 [list address_city "#intranet-core.City#" 9 textbox_medium ""] \
			 [list address_state "#intranet-core.State#" 10 textbox_medium ""] \
			 [list address_postal_code "#intranet-core.ZIP#" 11 textbox_small ""] \
			 [list address_country_code "#intranet-core.Country#" 12 country_codes ""] \
			 [list landlord "#intranet-core.Landlord#" 13 textarea_small_nospell ""] \
			 [list security "#intranet-core.Security#" 14 textarea_small_nospell ""] \
			 [list note "#intranet-core.Note#" 15 textarea_small_nospell ""]]

    set im_employee_list [list [list department_id "#intranet-cost.Deparment" 1 "departments" "1"] \
        [list supervisor_id "#intranet-hr.Supervisor#" 2 "supervisors" "1"] \
        [list availability "#intranet-hr.Availability_#" 3 "textbox_small" "1"] \
        [list hourly_cost "#intranet-hr.Hourly_Cost#" 4 "textbox_small" ""] \
        [list employee_status_id "#intranet-hr.Employee_Status#" 5 "employee_status" "1"] \
        [list ss_number "#intranet-hr.Social_Security_#" 6 "textbox_medium" ""] \
        [list salary "#intranet-hr.Monthly_Salary#" 7 "textbox_medium" ""] \
        [list social_security "#intranet-hr.lt_Monthly_Social_Securi#" 8 "textbox_small" ""] \
        [list insurance "#intranet-hr.Monthly_Insurance#" 9 "textbox_small" ""] \
        [list currency "#intranet-hr.Currency#" 11 "currencies" ""] \
        [list salary_payments_per_year "#intranet-hr.lt_Salary_Payments_per_Y#" 12 "textbox_small" ""] \
        [list birthdate "#intranet-hr.Birthdate#" 13 "textbox_small" ""] \
        [list job_title "#intranet-hr.Job_Title#" 14 "textbox_medium" ""] \
        [list job_description "#intranet-hr.Job_Description#" 15 "textarea_small_nospell" ""] \
        [list start_date "#intranet-hr.Start_date#" 16 "date" ""] \
        [list end_date "#intranet-hr.End_date#" 17 "date" ""] \
        [list voluntary_termination_p "#intranet-hr.lt_Voluntary_Termination#" 18 "checkbox" ""] \
        [list termination_reason "#intranet-hr.Termination_Reason#" 19 "textarea_small_nospell" ""] \
        [list signed_nda_p "#intranet-hr.NDA_Signed#" 20 "checkbox" ""] \
    ]
    
    # create the lists
    foreach type_list [list [list im_company_list im_company im_companies] [list im_office_list im_office im_offices] [list person_list person users_contact] [list im_employee_list person im_employees]] {
	    # Create a new category for this list with the same name
	    set object_list [lindex $type_list 0]
	    set object_type [lindex $type_list 1]
	    set table_name [lindex $type_list 2]
	    set object_type_category [db_string otypecat "select type_category_type from acs_object_types where object_type = :object_type" -default ""]
	    db_string newcat "select im_category_new(nextval('im_categories_seq')::integer,:object_type, :object_type_category)"
	
	    set exists_p [ams::list::exists_p -object_type $object_type -list_name $object_type]
	    if {!$exists_p} {
	        ns_log Error [lang::message::lookup "" intranet-dynfield.Unable_to_create_AMS_list "Unable to create AMS List"]
	        ad_script_abort
	    } else {
	        set list_id [ams::list::get_list_id -object_type "$object_type" -list_name "$object_type"]
		foreach element [set $object_list] {
		    catch { 
			set dynfield_attribute_id [im_dynfield::attribute::add -object_type $object_type \
						       -pos_y [lindex $element 2] -widget_name [lindex $element 3] \
						       -attribute_name [lindex $element 0] -pretty_name [lindex $element 1] \
						       -pretty_plural [lindex $element 1] -required_p [lindex $element 4] -table_name $table_name]
		    }
		}	        
	    }
	}

    # Standard person
    im_dynfield::attribute::add -object_type person -pos_y 1 -widget_name textbox_medium -attribute_name first_names -pretty_name "#acs-subsite.first_names#" -pretty_plural "#acs-subsite.first_names#" -table_name persons -required_p "1"
    im_dynfield::attribute::add -object_type person -pos_y 2 -widget_name textbox_medium -attribute_name last_name -pretty_name "#acs-subsite.last_name#" -pretty_plural "#acs-subsite.last_name#" -table_name persons -required_p 1
    im_dynfield::attribute::add -object_type party -pos_y 3 -widget_name textbox_medium -attribute_name email -pretty_name "#acs-subsite.Email#" -pretty_plural "#acs-subsite.Email#" -table_name parties -required_p 0
    im_dynfield::attribute::add -object_type party -pos_y 3 -widget_name textbox_medium -attribute_name url -pretty_name "#acs-subsite.URL#" -pretty_plural "#acs-subsite.URL#" -table_name parties -required_p 0

    im_dynfield::attribute::add -object_type person -pos_y 4 -widget_name salutation -attribute_name salutation_id -pretty_name "#intranet-contacts.Salutation#" -pretty_plural "#intranet-contacts.Salutation#" -table_name persons -required_p 0


    # Default searches
    contact::search::new -title "#intranet-contacts.search_person#" -object_type "person" -all_or_any all
    contact::search::new -title "#intranet-contacts.search_im_company#" -object_type "im_company" -all_or_any all
    contact::search::new -title "#intranet-contacts.search_im_office#" -object_type "im_office" -all_or_any all
    contact::search::new -title "#intranet-contacts.search_user#" -object_type "user" -all_or_any all


}

