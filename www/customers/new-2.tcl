# /www/intranet/customers/new-2.tcl

ad_page_contract {
    Writes all the customer information to the db. 

    @param customer_id The group this customer belongs to 
    @param start Date this customer starts.
    @param return_url The Return URL
    @param creation_ip_address IP Address of the creating user (if we're creating this group)
    @param creation_user User ID of the creating user (if we're creating this group)
    @param group_name Customer's name
    @param customer_path Group short name for things like email aliases
    @param referral_source How did this customer find us
    @param customer_status_id What's the customer's status
    @param customer_type_id The type of the customer
    @param annual_revenue.money How much they make
    @param note General notes about the customer

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

} {
    customer_id:integer,notnull
    { customer_name "" }
    { customer_path "" }
    { customer_status_id:integer "" }
    { customer_type_id:integer "" }
    { return_url "" }
    { group_type "" }
    { approved_p "" }
    { new_member_policy "" }
    { parent_group_id "" }
    { referral_source "" }
    { annual_revenue_id "" }
    { vat_number "" }
    { note "" }
    { contract_value "" }
    { site_concept "" }
    { manager_id "" }
    { billable_p "" }
    { start_date "" }
    { facility_id:integer 0 }
    { facility_name "" }
    { phone "" }
    { fax "" }
    { address_line1 "" }
    { address_line2 "" }
    { address_city "" }
    { address_postal_code "" }
    { address_country_code "" }
    { start:array,date "" }
    { old_customer_status_id "" }
    { status_modification_date.expr "" }
}

# -----------------------------------------------------------------
# Check for Errors in Input Variables
# -----------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set form_setid [ns_getform]

set required_vars [list \
    [list "customer_name" "You must specify the customer's name"] \
    [list "customer_path" "You must specify a short name"]]
set errors [im_verify_form_variables $required_vars]
set exception_count 0

if { ![empty_string_p $errors] } {
    incr exception_count
}

if { [string length ${note}] > 4000 } {
    incr exception_count
    append errors "  <li> The note you entered is too long. Please limit the note to 4000 characters\n"
}

# Periods don't work in bind variables...
set customer_path ${customer_path}
# Make sure customer name is unique
set exists_p [db_string group_exists_p "
	select count(*)
	from im_customers
	where lower(trim(customer_path))=lower(trim(:customer_path))
            and customer_id != :customer_id
"]

if { $exists_p } {
    incr exception_count
    append errors "  <li> The specified customer short name already exists. Either choose a new name or go back to the customer's page to edit the existing record\n"
}

if { ![empty_string_p $errors] } {
    ad_return_complaint $exception_count "<ul>$errors</ul>"
    return
}


# -----------------------------------------------------------------
# Make sure the Facility exists,
# independed whether it's a new or existing customer
# -----------------------------------------------------------------

# Make sure the facility exists to be able to store the 
# Address data
if {0 == $facility_id} {

    if {"" == $facility_name} { set facility_name "$customer_name Main Facility"}

    set facility_id [group::new \
	-context_id [ad_conn package_id] \
	-creation_user $user_id \
	-group_name "$facility_name Admin Group" \
	-creation_ip [ad_conn peeraddr]]

    set sql "
insert into im_facilities (facility_id, facility_name) 
values (:facility_id, :facility_name)"
    db_dml facility_insert $sql
}


# -----------------------------------------------------------------
# Create a new Customer if it didn't exist yet
# -----------------------------------------------------------------

# Double-Click protection: the customer Id was generated at the new.tcl page
set cust_count [db_string cust_count "select count(*) from im_customers where customer_id=:customer_id"]
if {0 == $cust_count} {

    set customer_id [group::new \
	-context_id [ad_conn package_id] \
	-creation_user $user_id \
	-group_name "$customer_name Admin Group" \
	-creation_ip [ad_conn peeraddr]]

    set sql "
insert into im_customers (customer_id, customer_name, customer_path) 
values (:customer_id,:customer_name,:customer_path)"
    db_dml customer_insert $sql

    # add the creating current user to the group
    relation_add \
	-member_state "approved" \
	"admin_rel" \
	$customer_id \
	$user_id
}


# -----------------------------------------------------------------
# Update the Facility
# -----------------------------------------------------------------

set update_sql "
update im_facilities set
	facility_name = :facility_name,
	phone = :phone,
	fax = :fax,
	address_line1 = :address_line1,
	address_line2 = :address_line2,
	address_city = :address_city,
	address_postal_code = :address_postal_code,
	address_country_code = :address_country_code
where
	facility_id = :facility_id
"
    db_dml update_facilities $update_sql


# -----------------------------------------------------------------
# Update the Customer
# -----------------------------------------------------------------

set update_sql "
update im_customers set
	customer_name		= :customer_name,
	customer_path		= :customer_path,
	vat_number		= :vat_number,
	customer_status_id	= :customer_status_id,
	old_customer_status_id	= :old_customer_status_id,
	customer_type_id	= :customer_type_id,
	referral_source		= :referral_source,
	start_date		= :start_date,
	annual_revenue_id	= :annual_revenue_id,
	contract_value		= :contract_value,
	site_concept		= :site_concept,
	manager_id		= :manager_id,
	billable_p		= :billable_p,
	note			= :note
where
	customer_id = :customer_id
"
    db_dml update_facilities $update_sql



db_release_unused_handles

ad_returnredirect $return_url
