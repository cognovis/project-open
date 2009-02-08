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

    # Register Relationships

    set contact [::im::dynfield::Rel_Types create contact_rel -object_type "contact_rel" -table_name im_contacts -supertype "relationship" -role_one "" -role_two "" -object_type_one "party" -object_type_two "party" -min_n_rels_one 0 -min_n_rels_two 0 -pretty_name "#intranet-contacts.contact_rel#" -pretty_plural "#intranet-contacts.contact_rels#" -sql_package_name "contact_rel"]
    $contact save_new
    
    # Employee
    rel_types::create_role -role "employee" -pretty_name "Employee" -pretty_plural "Employees"
    rel_types::create_role -role "employer" -pretty_name "Employer" -pretty_plural "Employers"
    set employee [::im::dynfield::Rel_Types create employment_rel -object_type "employment_rel" -table_name im_employee_rels -supertype "im_biz_object_member" -role_one "employer" -role_two "employee" -object_type_one "im_company" -object_type_two "person" -min_n_rels_one 1 -min_n_rels_two 1 -pretty_name "#intranet-contacts.employment_rel#" -pretty_plural "#intranet-contacts.employement_rels#" -sql_package_name "employee"]
    $employee save_new

	
    # Office member
    rel_types::create_role -role "office_member" -pretty_name "Office member" -pretty_plural "Office members"
    rel_types::create_role -role "office" -pretty_name "Office" -pretty_plural "Offices"
    set office_member [::im::dynfield::Rel_Types create office_member_rel -object_type "office_member_rel" -table_name im_office_members -supertype "im_biz_object_member" -role_one "office" -role_two "office_member" -object_type_one "im_office" -object_type_two "person" -min_n_rels_one 1 -min_n_rels_two 1 -pretty_name "#intranet-contacts.office_member_rel#" -pretty_plural "#intranet-contacts.office_member_rels#" -sql_package_name "office_member"]
    $office_member save_new
    
    # company member
    rel_types::create_role -role "company_member" -pretty_name "company member" -pretty_plural "company members"
    rel_types::create_role -role "im_company" -pretty_name "Company" -pretty_plural "Companies"
    set company_member [::im::dynfield::Rel_Types create company_member_rel -object_type "company_member_rel" -table_name im_company_members -supertype "im_biz_object_member" -role_one "im_company" -role_two "company_member" -object_type_one "im_company" -object_type_two "person" -min_n_rels_one 1 -min_n_rels_two 1 -pretty_name "#intranet-contacts.company_member_rel#" -pretty_plural "#intranet-contacts.company_member_rels#" -sql_package_name "company_member"]
    $company_member save_new
     
    # Office 
    set office [::im::dynfield::Rel_Types create office_rel -object_type "office_rel" -table_name im_office_rels -supertype "contact_rel" -role_one "office" -role_two "im_company" -object_type_one "im_office" -object_type_two "im_company" -min_n_rels_one 1 -min_n_rels_two 1 -pretty_name "#intranet-contacts.office_rel#" -pretty_plural "#intranet-contacts.office_rels#" -sql_package_name "office"]
    $office save_new
    
    # Main Office
    rel_types::create_role -role "main_office" -pretty_name "Main Office" -pretty_plural "Main Offices"
    set main_office [::im::dynfield::Rel_Types create main_office_rel -object_type "main_office_rel" -table_name im_main_offices -supertype "office_rel" -role_one "main_office" -role_two "im_company" -object_type_one "im_office" -object_type_two "im_company" -min_n_rels_one 1 -min_n_rels_two 1 -pretty_name "#intranet-contacts.main_office_rel#" -pretty_plural "#intranet-contacts.main_office_rels#" -sql_package_name "main_office"]
    $main_office save_new

}

ad_proc -public contacts::install::package_instantiate {
    -package_id
} {
    Instantiate the package and install the searches
} {
    # Default searches
contact::search::new -title "#intranet-contacts.search_person#" -object_type "person" -package_id $package_id -all_or_any all -owner_id $package_id
contact::search::new -title "#intranet-contacts.search_im_company#" -object_type "im_company" -package_id $package_id -all_or_any all -owner_id $package_id
contact::search::new -title "#intranet-contacts.search_im_office#" -object_type "im_office" -package_id $package_id -all_or_any all -owner_id $package_id
contact::search::new -title "#intranet-contacts.search_user#" -object_type "user" -package_id $package_id -all_or_any all -owner_id $package_id

    set ttt {


    # We need to fill acs_object_type_tables with the correct values
    # As the automated class generation cannot deal with this
    catch { db_dml insert "insert into acs_object_type_tables values ('person','users_contact','user_id')" }
    catch { db_dml insert "insert into acs_object_type_tables values ('person','parties','party_id')" }
    catch { db_dml insert2 "insert into im_biz_objects select company_id from im_companies" }
    catch { db_dml insert2 "insert into im_biz_objects select office_id from im_offices" }
    catch { db_dml cleanup "update acs_attributes set table_name = 'persons' where object_type = 'person' and table_name is null"  }
    catch { db_dml salutation "alter table persons add column salutation_id integer references im_categories(category_id)" }
    
    catch { contacts::install::add_widgets }
    catch { contacts::install::add_dynfields -package_id $package_id }
    catch { contacts::install::required_attributes }
    catch { contacts::install::update_data }
    
    # Add the menu
    catch { ::xo::db::sql::im_menu new -package_name intranet-contacts -label "intranet_contacts"  -name "CRM"  -url "/intranet-contacts"  -sort_order 20  -parent_menu_id [db_string get "select menu_id from im_menus where label = 'main'" -default 476] }
    
    # Deal with groups in a "smart" way
    set object_type_category "Intranet Groups"   
    foreach groups [db_list_of_lists groups "select group_id, group_name from groups where group_id >0"] {
        util_unlist $groups group_id group_name
        set category_id [db_string newcat "select im_category_new(nextval('im_categories_seq')::integer,:group_id, :object_type_category)"]
        db_dml update "update im_categories set aux_string1 = '$group_name List' where category = :group_id"
    }

    db_dml update "update acs_object_types set type_category_type = 'Intranet Groups' where object_type = 'group'"
    
    db_dml update "update acs_object_type_tables set id_column = 'employee_id' where table_name = 'im_employees'"
    
    db_dml insert "insert into im_employees (employee_id) select person_id from persons where person_id not in (select employee_id from im_employees)"
    
    db_dml insert "alter table im_employees add column start_date date"
    db_dml alter "alter table im_employees add column end_date date"

}
}

ad_proc -public contacts::install::update_data {
} {
    Update the data and insert the relationships
} {
    set employee_id [im_employee_group_id]
    set internal_id [im_company_internal]
    set key_account_id [im_biz_object_role_key_account]
    
    # Insert the employees of other companies as a relationship
    db_dml insert {insert into im_employee_rels 
        select rel_id from acs_rels,im_companies 
        where object_id_two not in (select member_id from group_approved_member_map where group_id = :employee_id) 
        and rel_type = 'im_biz_object_member' and object_id_one = company_id}

    # Insert our own employees as a relationship
    db_dml insert {insert into im_employee_rels 
        select rel_id from acs_rels 
        where object_id_two in (select member_id from group_approved_member_map where group_id = :employee_id) 
        and rel_type = 'im_biz_object_member' 
        and object_id_one = :internal_id}

    db_dml update "update acs_rels set rel_type = 'employment_rel' where rel_id in (select employment_rel_id from im_employee_rels)"
    
    # Insert our employees as account managers
    db_dml insert {insert into im_company_members
        select rel_id from acs_rels,im_companies 
        where object_id_two in (select member_id from group_approved_member_map where group_id = :employee_id) 
        and rel_type = 'im_biz_object_member' 
        and object_id_one not in (:internal_id) and object_id_one = company_id}

    db_dml update "update acs_rels set rel_type = 'company_member_rel' where rel_id in (select company_member_rel_id from im_company_members)"
    
    # Insert the employees in the offices
    db_dml insert {insert into im_office_members
        select rel_id from acs_rels,im_offices
        where rel_type = 'im_biz_object_member'
        and office_id = object_id_one}

    db_dml update "update acs_rels set rel_type = 'office_member_rel' where rel_id in (select office_member_rel_id from im_office_members)"    

    # Insert the offices with the companies
    set class [::im::dynfield::Class object_type_to_class "office_rel"]
    ::im::dynfield::Class get_class_from_db -object_type "office_rel"
    db_foreach office_rels {select company_id, office_id from im_offices where company_id not in (select main_office_id from im_companies)} {
        set relation [$class create ::office_id]
        $relation set rel_type "office_rel"
        $relation set object_id_one $office_id
        $relation set object_id_two $company_id
        $relation save_new
    }
    
    # Insert the main offices with the companies
    set class [::im::dynfield::Class object_type_to_class "main_office_rel"]
    ::im::dynfield::Class get_class_from_db -object_type "main_office_rel"
    db_foreach office_rels {select company_id, main_office_id as office_id from im_companies} {
        set relation [$class create ::office_id]
        $relation set rel_type "main_office_rel"
        $relation set object_id_one $office_id
        $relation set object_id_two $company_id
        $relation save_new
    }
}

ad_proc -public contacts::install::add_dynfields {
    -package_id
} {
    Add the dynfields for im_company
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
                set dynfield_attribute_id [im_dynfield::attribute::add -object_type $object_type \
                    -pos_y [lindex $element 2] -widget_name [lindex $element 3] \
                    -attribute_name [lindex $element 0] -pretty_name [lindex $element 1] \
                    -pretty_plural [lindex $element 1] -required_p [lindex $element 4] -table_name $table_name]
            }	        
	    }
    }

    # Standard person
    im_dynfield::attribute::add -object_type person -pos_y 1 -widget_name textbox_medium -attribute_name first_names -pretty_name "#acs-subsite.first_names#" -pretty_plural "#acs-subsite.first_names#" -table_name persons -required_p "1"
    im_dynfield::attribute::add -object_type person -pos_y 2 -widget_name textbox_medium -attribute_name last_name -pretty_name "#acs-subsite.last_name#" -pretty_plural "#acs-subsite.last_name#" -table_name persons -required_p 1
    im_dynfield::attribute::add -object_type party -pos_y 3 -widget_name textbox_medium -attribute_name email -pretty_name "#acs-subsite.Email#" -pretty_plural "#acs-subsite.Email#" -table_name parties -required_p 0
    im_dynfield::attribute::add -object_type party -pos_y 3 -widget_name textbox_medium -attribute_name url -pretty_name "#acs-subsite.URL#" -pretty_plural "#acs-subsite.URL#" -table_name parties -required_p 0

    im_dynfield::attribute::add -object_type person -pos_y 4 -widget_name salutation -attribute_name salutation_id -pretty_name "#intranet-contacts.Salutation#" -pretty_plural "#intranet-contacts.Salutation#" -table_name persons -required_p 0


    ::xo::db::sql::im_category new -category_id [db_nextval im_categories_seq] -category "Dear Mr." -category_type "Intranet Salutation" -description ""
    ::xo::db::sql::im_category new -category_id [db_nextval im_categories_seq] -category "Dear Mrs." -category_type "Intranet Salutation" -description ""
    ::xo::db::sql::im_category new -category_id [db_nextval im_categories_seq] -category "Dear Ladies and Gentlemen" -category_type "Intranet Salutation" -description ""


}

ad_proc -public contacts::install::add_widgets {
} {
    Add the widgets which we need for the companies, persons and offices
} {
    
    xo::db::sql::im_dynfield_widget new \
        -widget_id "" \
        -creation_date "" \
        -creation_user "" \
        -creation_ip "" \
        -context_id "" \
        -object_type "im_dynfield_widget" \
        -widget_name "category_company_status" \
	-pretty_name "#intranet-core.Company_Status#" \
	-pretty_plural "#intranet-core.Company_Status#" \
	-storage_type_id 10007 \
	-acs_datatype "integer" \
	-widget "im_category_tree" \
	-sql_datatype "integer" \
	-parameters [list [list custom [list category_type "Intranet Company Status"]]]
				
    xo::db::sql::im_dynfield_widget new \
	-widget_id "" \
	-creation_date "" \
	-creation_user "" \
	-creation_ip "" \
	-context_id "" \
	-object_type "im_dynfield_widget" \
	-widget_name "annual_revenue" \
	-pretty_name "#intranet-core.Annual_Revenue#" \
	-pretty_plural "#intranet-core.Annual_Revenue#" \
	-storage_type_id 10007 \
	-acs_datatype "integer" \
	-widget "im_category_tree" \
	-sql_datatype "integer" \
	-parameters [list [list custom [list category_type "Intranet Annual Revenue"]]]
        
    xo::db::sql::im_dynfield_widget new \
	-widget_id "" \
	-creation_date "" \
	-creation_user "" \
	-creation_ip "" \
	-context_id "" \
	-object_type "im_dynfield_widget" \
	-widget_name "country_codes" \
	-pretty_name "#intranet-core.Country#" \
	-pretty_plural "#intranet-core.Country#" \
	-storage_type_id 10007 \
	-acs_datatype "string" \
	-widget "generic_sql" \
	-sql_datatype "char(3)" \
	-parameters [list [list custom [list sql "select iso,country_name from country_codes order by country_name"]]]

# ToDo: fix:
#	-deref_function "im_country_from_code" \


    xo::db::sql::im_dynfield_widget new \
        -widget_id "" \
        -creation_date "" \
        -creation_user "" \
        -creation_ip "" \
        -context_id "" \
        -object_type "im_dynfield_widget" \
        -widget_name "employee_status" \
        -pretty_name "#intranet-hr.Employee_Status#" \
        -pretty_plural "#intranet-hr.Employee_Status#" \
    	-storage_type_id 10007 \
    	-acs_datatype "integer" \
    	-widget "im_category_tree" \
    	-sql_datatype "integer" \
    	-parameters [list [list custom [list category_type "Intranet Employee Pipeline State"]]]


    xo::db::sql::im_dynfield_widget new \
        -widget_id "" \
        -creation_date "" \
        -creation_user "" \
        -creation_ip "" \
        -context_id "" \
        -object_type "im_dynfield_widget" \
        -widget_name "salutation" \
        -pretty_name "#intranet-contacts.Salutation#" \
        -pretty_plural "#intranet-contacts.Salutation#" \
        -storage_type_id 10007 \
        -acs_datatype "integer" \
        -widget "im_category_tree" \
        -sql_datatype "integer" \
        -parameters [list [list custom [list category_type "Intranet Salutation"]]]
	
    xo::db::sql::im_dynfield_widget new \
	-widget_id "" \
	-creation_date "" \
	-creation_user "" \
	-creation_ip "" \
	-context_id "" \
	-object_type "im_dynfield_widget" \
	-widget_name "supervisors" \
	-pretty_name "#intranet-hr.Supervisor#" \
	-pretty_plural "#intranet-hr.Supervisor#" \
	-storage_type_id 10007 \
	-acs_datatype "integer" \
	-widget "generic_sql" \
	-sql_datatype "integer" \
	-parameters [list [list custom [list sql "select 
                0 as user_id,
                'No Supervisor (CEO)' as user_name
        from dual
    UNION
        select 
                u.user_id,
                im_name_from_user_id(u.user_id) as user_name
        from 
                users u,
                group_distinct_member_map m
        where 
                m.member_id = u.user_id
                and m.group_id = [im_employee_group_id]"]]]
	
	xo::db::sql::im_dynfield_widget new \
        -widget_id "" \
        -creation_date "" \
        -creation_user "" \
        -creation_ip "" \
        -context_id "" \
        -object_type "im_dynfield_widget" \
        -widget_name "category_office_status" \
	-pretty_name "#intranet-core.Office_Status#" \
	-pretty_plural "#intranet-core.Office_Status#" \
	-storage_type_id 10007 \
	-acs_datatype "integer" \
	-widget "im_category_tree" \
	-sql_datatype "integer" \
	-parameters [list [list custom [list category_type "Intranet Office Status"]]]
	
    xo::db::sql::im_dynfield_widget new \
        -widget_id "" \
        -creation_date "" \
        -creation_user "" \
        -creation_ip "" \
        -context_id "" \
        -object_type "im_dynfield_widget" \
        -widget_name "category_office_type" \
	-pretty_name "#intranet-core.Office_Type#" \
	-pretty_plural "#intranet-core.Office_Type#" \
	-storage_type_id 10007 \
	-acs_datatype "integer" \
	-widget "im_category_tree" \
	-sql_datatype "integer" \
	-parameters [list [list custom [list category_type "Intranet Office Type"]]]
}

ad_proc -public contacts::install::required_attributes {
} {
    Set the required attributes as per database
} {
    set not_null_attributes [db_list required "select ida.attribute_id
    from acs_attributes aa, im_dynfield_attributes ida, pg_catalog.pg_attribute pga, pg_catalog.pg_class pgc
    where aa.attribute_id = ida.acs_attribute_id
    and pgc.relname = aa.table_name
    and pga.attname = attribute_name
    and pga.attrelid = pgc.oid
    and pga.attnotnull = 't'"]
    
    foreach attribute_id $not_null_attributes {
        db_dml update "update im_dynfield_type_attribute_map set required_p = 't' where attribute_id = :attribute_id"
        db_dml update "update acs_attributes set min_n_values = 1 where attribute_id = (select acs_attribute_id from im_dynfield_attributes where attribute_id = :attribute_id) "
    }
}

ad_proc -public contacts::insert_map {
    {-group_id:required}
    {-default_p:required}
    {-package_id:required}
} {
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-06-03

    @param group_id

    @param default_p

    @param package_id

    @return

    @error
} {
    db_dml insert_map {
        insert into contact_groups
        (group_id,default_p,package_id)
        values
        (:group_id,:default_p,:package_id)}
}

ad_proc -public ::install::xml::action::contacts_pop_crm {
    node
} { 
    Procedure to register the populate crm for the install.xml
} {
    set url [apm_required_attribute_value $node url]
    array set sn_array [site_node::get -url $url]
    contacts::populate::crm -package_id $sn_array(object_id)
}


ad_proc -public contacts::install::package_upgrade {
    {-from_version_name:required}
    {-to_version_name:required}
} {
    @author Miguel Marin (miguelmarin@viaro.net)
    @author Viaro Networks www.viaro.net
    @creation-date 2005-10-05
} {
    apm_upgrade_logic \
        -from_version_name $from_version_name \
        -to_version_name $to_version_name \
        -spec {
	    1.0d18 1.0d19 {
        }
	}

}

