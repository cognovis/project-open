ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @author Frank Bergmann frank.bergmann@project-open.com
    @author Malte Sussdorff
    @creation-date 2008-03-28
    @cvs-id $Id$

	@param object_type
		Defines the object to be created/saved

	@param group_ids 
		List of groups for the person to be added to.
		Groups are linked via categories (of the same name) to
		the DynField attributes to be shown.

	@param list_ids 
		List of object-subtypes for the im_company or im_office to 
		be created.
	
	@param object_types
		List of objects to create using this page. We will also
		create a link between these object types.
		Example: im_company + person => + company-person-membership
} {
    person_id:optional
    {form_mode "edit" }
    {return_url ""}
}

# --------------------------------------------------
# Append the option to create a user who get's a welcome message send
# Furthermore set the title.

set title "[_ intranet-contacts.Add_a_Biz_Card]"
set context [list $title]
set current_user_id [ad_maybe_redirect_for_registration]


# --------------------------------------------------
# Environment information for the rest of the page

set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set user_id [ad_conn user_id]
set peeraddr [ad_conn peeraddr]

set required_field "<font color=red size=+1><B>*</B></font>"


if {[info exists person_id]} {
    set company_count [db_string cc "
	select	count(*)
	from	acs_rels r,
		im_companies c
	where	r.object_id_one = :person_id and
		r.object_id_two = c.company_id
    "]
    if {$company_count > 1} {
	ad_return_complaint 1 "More then one company for this user" 
    }
}


# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set company_status_options [list]
set company_type_options [list]
set annual_revenue_options [list]
set country_options [im_country_options]
set employee_options [im_employee_options]

set form_id "company"

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -mode $form_mode \
    -export {next_url user_id return_url} \
    -form {
	person_id:key
	{company_id:text(hidden)}
	{office_id:text(hidden)}
    }


# ------------------------------------------------------
# Dynamic Fields
# ------------------------------------------------------

set form_id "company"
set object_type "im_company"

im_dynfield::append_attributes_to_form \
    -object_type "person" \
    -form_id $form_id

im_dynfield::append_attributes_to_form \
    -object_type "im_company" \
    -form_id $form_id


im_dynfield::append_attributes_to_form \
    -object_type "im_office" \
    -form_id $form_id


ad_form -extend -name $form_id -new_request {

    # Set variables for empty form
    set company_id [im_new_object_id]
    set office_id [im_new_object_id]

    set company_type_id [im_company_type_customer]
    set company_status_id [im_company_status_active]
    set office_type_id [im_office_type_main]

} -on_submit {

    # First create the user
    # Create the company
    # Create the office
    # Make the office the main_office of ocmpany
    # Make the user a member of the company

    set exception_count 0
    set normalize_company_path_p [parameter::get_from_package_key -package_key "intranet-core" -parameter "NormalizeCompanyPathP" -default 1]
    
    if {$normalize_company_path_p} {
	set company_path [string tolower [string trim $company_path]]
	
	if {![regexp {^[a-z0-9_]+$} $company_path match]} {
	    incr exception_count
	    append errors "  <li>[lang::message::lookup "" intranet-core.Non_alphanum_chars_in_path "The specified path contains invalid characters. Allowed are only aphanumeric characters from a-z, 0-9 and '_'."]: '$company_path'"
	}
    }
    

    # Make sure company name is unique
    set exists_p [db_string group_exists_p "
	select count(*)
	from im_companies
	where lower(trim(company_path))=lower(trim(:company_path))
            and company_id != :company_id
    "]

    if { $exists_p } {
	incr exception_count
	append errors "  <li>[_ intranet-core._The]"
    }
    
    if { [exists_and_not_null errors] } {
	ad_return_complaint $exception_count "<ul>$errors</ul>"
	return
    }
    

    # ------------------------------------------------------------------
    # Permissions
    # ------------------------------------------------------------------
    
    # Check if we are creating a new company or editing an existing one:
    set company_exists_p 0
    if {[info exists company_id]} {
	set company_exists_p [db_string company_exists "
        select count(*)
        from im_companies
        where company_id = :company_id
        "]
    }

    if {$company_exists_p} {
	
	# Check company permissions for this user
	im_company_permissions $user_id $company_id view read write admin
	if {!$write} {
	    ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "
            <li>[_ intranet-core.lt_You_dont_have_suffici]"
	    return
	}
	
    } else {
	
	if {![im_permission $user_id add_companies]} {
	    ad_return_complaint "[_ intranet-core.lt_Insufficient_Privileg]" "
            <li>[_ intranet-core.lt_You_dont_have_suffici]"
	    return
	}
	
    }

    
    # -----------------------------------------------------------------
    # Create a new Company if it didn't exist yet
    # -----------------------------------------------------------------
    
    if {![exists_and_not_null office_name]} {
	set office_name "$company_name [_ intranet-core.Main_Office]"
    }
    if {![exists_and_not_null office_path]} {
	set office_path "$company_path"
    }
    
    # Double-Click protection: the company Id was generated at the new.tcl page
    if {0 == $company_exists_p} {
	
	db_transaction {
	    # First create a new main_office:
	    set main_office_id [office::new \
				    -office_name	$office_name \
				    -company_id     $company_id \
				    -office_type_id [im_office_type_main] \
				    -office_status_id [im_office_status_active] \
				    -office_path	$office_path]
	    
	    # add users to the office as 
	    set role_id [im_biz_object_role_office_admin]
	    im_biz_object_add_role $user_id $main_office_id $role_id
	    
	    ns_log Notice "/companies/new-2: main_office_id=$main_office_id"
	    
	    
	    # Now create the company with the new main_office:
	    set company_id [company::new \
				-company_id $company_id \
				-company_name	$company_name \
				-company_path	$company_path \
				-main_office_id	$main_office_id \
				-company_type_id $company_type_id \
				-company_status_id $company_status_id]
	    
	    # add users to the company as key account
	    set role_id [im_biz_object_role_key_account]
	    im_biz_object_add_role $user_id $company_id $role_id
	    
	}
    }
    
    # -----------------------------------------------------------------
    # Update the Office
    # -----------------------------------------------------------------
    
    set update_sql "
update im_offices set
	office_name = :office_name,
	phone = :phone,
	fax = :fax,
	address_line1 = :address_line1,
	address_line2 = :address_line2,
	address_city = :address_city,
	address_state = :address_state,
	address_postal_code = :address_postal_code,
	address_country_code = :address_country_code
where
	office_id = :main_office_id
    "
    db_dml update_offices $update_sql


    # -----------------------------------------------------------------
    # Update the Company
    # -----------------------------------------------------------------
    
    set update_sql "
update im_companies set
	company_name		= :company_name,
	company_path		= :company_path,
	vat_number		= :vat_number,
	company_status_id	= :company_status_id,
	old_company_status_id	= :old_company_status_id,
	company_type_id	= :company_type_id,
	referral_source		= :referral_source,
	start_date		= :start_date,
	annual_revenue_id	= :annual_revenue_id,
	contract_value		= :contract_value,
	site_concept		= :site_concept,
	manager_id		= :manager_id,
	billable_p		= :billable_p,
	note			= :note
where
	company_id = :company_id
    "
    db_dml update_company $update_sql

    # -----------------------------------------------------------------
    # Make sure the creator and the manager become Key Accounts
    # -----------------------------------------------------------------
    
    set role_id [im_company_role_key_account]
    
    im_biz_object_add_role $user_id $company_id $role_id
    if {"" != $manager_id } {
	im_biz_object_add_role $manager_id $company_id $role_id
    }
    
    
    # -----------------------------------------------------------------
    # Store dynamic fields
    # -----------------------------------------------------------------
    
    set form_id "company"
    set object_type "im_company"
    
    ns_log Notice "companies/new-2: before append_attributes_to_form"
    im_dynfield::append_attributes_to_form \
	-object_type im_company \
	-form_id company \
	-object_id $company_id
    
    ns_log Notice "companies/new-2: before attribute_store"
    im_dynfield::attribute_store \
	-object_type $object_type \
	-object_id $company_id \
	-form_id $form_id
    
    
    
    # ------------------------------------------------------
    # Finish
    # ------------------------------------------------------
    
    db_release_unused_handles
    
    
    # Return to the new company page after creating
    if {"" == $return_url} {
	set return_url [export_vars -base "/intranet/companies/view?" {company_id}]
    }

} -after_submit {
    
    ad_returnredirect $return_url
    ad_script_abort
}


