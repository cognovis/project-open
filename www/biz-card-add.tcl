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
    -form_id $form_id \
    -page_url "/intranet-contacts/biz-card-add" 


im_dynfield::append_attributes_to_form \
    -object_type "im_company" \
    -form_id $form_id \
    -page_url "/intranet-contacts/biz-card-add" 


im_dynfield::append_attributes_to_form \
    -object_type "im_office" \
    -form_id $form_id \
    -page_url "/intranet-contacts/biz-card-add" 


ad_form -extend -name $form_id -new_request {

    # Set variables for empty form
    set company_id [im_new_object_id]
    set office_id [im_new_object_id]

    set company_type_id [im_company_type_customer]
    set company_status_id [im_company_status_active]
    set office_type_id [im_office_type_main]

} -on_submit {

    # ------------------------------------------------------------------
    # Checks & Normalization
    # ------------------------------------------------------------------
    
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
    # Create user
    # -----------------------------------------------------------------
    
    set user_id [db_string first_last_name_exists_p "
	select	person_id
	from	persons
	where	lower(trim(first_names)) = lower(trim(:first_names)) and
		lower(trim(last_name)) = lower(trim(:last_name)
    " -default ""]

    if {![info exists email]} { set email "" }

    if {"" == $user_id} {

	    # New user: create from scratch
	    set email [string trim $email]
	    set similar_user [db_string similar_user "select party_id from parties where lower(email) = lower(:email)" -default 0]
	    
	    if {$similar_user > 0} {
			set view_similar_user_link "<A href=/intranet/users/view?user_id=$similar_user>[_ intranet-core.user]</A>"
			ad_return_complaint 1 "<li><b>[_ intranet-core.Duplicate_UserB]<br>
        	        [_ intranet-core.lt_There_is_already_a_vi]<br>"
			return
	    }

	    if {![info exists password] || [empty_string_p $password]} {
		set password [ad_generate_random_string]
		set password_confirm $password
	    }

	    ns_log Notice "/users/new: Before auth::create_user"
	    array set creation_info [auth::create_user \
					 -user_id $user_id \
					 -verify_password_confirm \
					 -username $username \
					 -email $email \
					 -first_names $first_names \
					 -last_name $last_name \
					 -screen_name $screen_name \
					 -password $password \
					 -password_confirm $password_confirm \
					 -url $url \
					 -secret_question $secret_question \
					 -secret_answer $secret_answer]

	    # Update creation user to allow the creator to admin the user
	    db_dml update_creation_user_id "
		update acs_objects
		set creation_user = :current_user_id
		where object_id = :user_id
	    "

	} else {

	    # Existing user: Update variables
	    set auth [auth::get_register_authority]
	    set user_data [list]

	    # Make sure the "person" exists.
	    # This may be not the case when creating a user from a party.
	    set person_exists_p [db_string person_exists "select count(*) from persons where person_id = :user_id"]
	    if {!$person_exists_p} {
		db_dml insert_person "
		    insert into persons (
			person_id, first_names, last_name
		    ) values (
			:user_id, :first_names, :last_name
		    )
		"	
		# Convert the party into a person
		db_dml person2party "
		    update acs_objects
		    set object_type = 'person'
		    where object_id = :user_id
		"	
	    }

	    set user_exists_p [db_string user_exists "select count(*) from users where user_id = :user_id"]
	    if {!$user_exists_p} {
		if {"" == $username} { set username $email} 
		db_dml insert_user "
		    insert into users (
			user_id, username
		    ) values (
			:user_id, :username
		    )
		"
		# Convert the person into a user
		db_dml party2user "
		    update acs_objects
		    set object_type = 'user'
		    where object_id = :user_id
		"
	    }


	    ns_log Notice "/users/new: person::update -person_id=$user_id -first_names=$first_names -last_name=$last_name"
	    person::update \
		-person_id $user_id \
		-first_names $first_names \
		-last_name $last_name
	    
	    ns_log Notice "/users/new: party::update -party_id=$user_id -url=$url -email=$email"
	    party::update \
		-party_id $user_id \
		-url $url \
		-email $email
	    
	    ns_log Notice "/users/new: acs_user::update -user_id=$user_id -screen_name=$screen_name"
	    acs_user::update \
		-user_id $user_id \
		-screen_name $screen_name \
		-username $username
	}

        # Add the user to some companies or projects
        array set also_add_hash $also_add_to_biz_object
        foreach oid [array names also_add_hash] {
	    set object_type [db_string otype "select object_type from acs_objects where object_id=:oid"]
	    set perm_cmd "${object_type}_permissions \$current_user_id \$oid object_view object_read object_write object_admin"
	    eval $perm_cmd
	    if {$object_write} {
		set role_id $also_add_hash($oid)
		im_biz_object_add_role $user_id $oid $role_id
	    }
	}

	# For all users (new and existing one):
        # Add a users_contact record to the user since the 3.0 PostgreSQL
        # port, because we have dropped the outer join with it...
        catch { db_dml add_users_contact "insert into users_contact (user_id) values (:user_id)" } errmsg


        # Add the user to the "Registered Users" group, because
        # (s)he would get strange problems otherwise
        set registered_users [db_string registered_users "select object_id from acs_magic_objects where name='registered_users'"]
        set reg_users_rel_exists_p [db_string member_of_reg_users "
		select	count(*) 
		from	group_member_map m, membership_rels mr
		where	m.member_id = :user_id
			and m.group_id = :registered_users
			and m.rel_id = mr.rel_id 
			and m.container_id = m.group_id 
			and m.rel_type::text = 'membership_rel'::text
	"]
	if {!$reg_users_rel_exists_p} {
	    relation_add -member_state "approved" "membership_rel" $registered_users $user_id
	}


	# TSearch2: We need to update "persons" in order to trigger the TSearch2
	# triggers
	db_dml update_persons "
		update persons
		set first_names = first_names
		where person_id = :user_id
        "

	ns_log Notice "/users/new: finished big IF clause"

	
        set membership_del_sql "
        select
                r.rel_id
        from
                acs_rels r,
                acs_objects o
        where
                object_id_two = :user_id
                and object_id_one = :profile_id
                and r.object_id_one = o.object_id
                and o.object_type = 'im_profile'
                and rel_type = 'membership_rel'
        "









    
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
				    -company_id		$company_id \
				    -office_type_id	[im_office_type_main] \
				    -office_status_id	[im_office_status_active] \
				    -office_path	$office_path]

	    # add users to the office as 
	    set role_id [im_biz_object_role_office_admin]
	    im_biz_object_add_role $user_id $main_office_id $role_id
	    
	    ns_log Notice "/companies/new-2: main_office_id=$main_office_id"
	    
	    
	    # Now create the company with the new main_office:
	    set company_id [company::new \
				-company_id		$company_id \
				-company_name		$company_name \
				-company_path		$company_path \
				-main_office_id		$main_office_id \
				-company_type_id	$company_type_id \
				-company_status_id	$company_status_id]
	    
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

    if {![info exists contract_value]} { set contract_value "" }
    if {![info exists billable_p]} { set billable_p "" }
    
    set update_sql "
		update im_companies set
			company_name		= :company_name,
			company_path		= :company_path,
			vat_number		= :vat_number,
			company_status_id	= :company_status_id,
			company_type_id		= :company_type_id,
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


