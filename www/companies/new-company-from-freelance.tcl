# /packages/intranet-trans-invoices/www/companies/new-company-from-freelance.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    Creates and updates a company for a specific freelancer.
    This is necessary because invoicing and financial documents
    work on the level of companies while user log-in and 
    task assignments work on the level of users (natural
    persons).

    @author Frank Bergmann (frank.bergmann@project-open.com)

} {
    freelance_id:integer
}

# -----------------------------------------------------------------
# Default & Security
# -----------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
if {![im_permission $user_id add_customers]} {
    ad_return_complaint 1 "<li>You have insufficient permissions to view this page"
    return
}

# -----------------------------------------------------------------
# Get everything about the freelancer
# -----------------------------------------------------------------

db_1row freelancer_info "
select
	u.*,
	f.*,
	c.*,
	pe.*,
	pa.*
from
	users u,
	im_freelancers f,
	users_contact c,
	persons pe,
	parties pa,
        country_codes ha_cc,
        country_codes wa_cc
where
	u.user_id = :freelance_id
	and u.user_id = f.user_id(+)
	and u.user_id = c.user_id(+)
	and u.user_id = pe.person_id(+)
	and u.user_id = pa.party_id(+)
        and c.ha_country_code = ha_cc.iso(+)
        and c.wa_country_code = wa_cc.iso(+)
"

set manager_id ""

# -----------------------------------------------------------------
# Setup Company Fields
# -----------------------------------------------------------------

set company_path "${freelance_id}_freelance"
set company_id [db_string company_id "select customer_id from im_customers where customer_path=:company_path" -default 0]

if {!$company_id} {

    set company_name "$first_names $last_name Company"
    set company_type_id [im_customer_type_freelance]
    set company_status_id [im_customer_status_active]

    set office_name "$first_names $last_name Office"
    set office_path "${freelance_id}_freelance"

    set office_id [db_string office_id "select office_id from im_offices where office_path=:office_path" -default 0]
    if {!$office_id} {
	# Create a new main_office:
	set office_id [office::new \
		-office_name	$office_name \
		-office_path	$office_path]
    }

    # Now create the customer with the new main_office:
    set company_id [customer::new \
	-customer_name	$company_name \
        -customer_path	$company_path \
        -main_office_id	$office_id \
        -customer_type_id $company_type_id \
        -customer_status_id $company_status_id]
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
	address_postal_code = :address_postal_code,
	address_country_code = :address_country_code
where
	office_id = :main_office_id
"
    db_dml update_offices $update_sql


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
    db_dml update_customer $update_sql

# -----------------------------------------------------------------
# Make sure the creator and the manager become Key Accounts
# -----------------------------------------------------------------

#set rel_count [db_string rel_count "select count(*) from acs_rels where object_id_one=:company_id and object_id_two = :freelance_id"]
#if {!$rel_count} {
#    # add the creating current user to the group
#    relation_add \
#	-member_state "approved" \
#	"admin_rel" \
#	$company_id \
#	$freelance_id
#}

set role_id [im_customer_role_key_account]

im_biz_object_add_role $user_id $company_id $role_id

#if {"" != $manager_id } {
#    im_biz_object_add_role $manager_id $customer_id $role_id
#}


db_release_unused_handles

ad_returnredirect $return_url
