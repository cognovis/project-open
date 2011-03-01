# /packages/intranet-ubl/www/invoice.xml.tcl
#
# Copyright (c) 2003 - 2009 ]project-open[
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Creates a UBL Universal Business Language XML structure for a financial document

    @author frank.bergmann@project-open.com
} {
    { invoice_id:integer "" }
}

# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set today [db_string today "select to_char(now(), 'YYYY-MM-DD')"]



# ---------------------------------------------------------------
# Get information about the financial document ("invoice")
# ---------------------------------------------------------------

if {![db_0or1row project_info "
	select	c.*,
		i.*,
		coalesce(i.invoice_office_id, cust.main_office_id) as cust_office_id,
		o.creation_date as issue_date,
		cust.company_name as customer_name,
		prov.company_name as provider_name,
		oprov.address_line1 as provider_address_line1,
		oprov.address_line2 as provider_address_line2,
		oprov.address_city as provider_address_city,
		oprov.address_state as provider_address_state,
		oprov.address_postal_code as provider_address_postal_code,
		oprov.address_country_code as provider_address_country_code,

		im_name_from_user_id(i.company_contact_id) as customer_contact_name,
		cust_contact.work_phone as customer_contact_work_phone,
		im_name_from_user_id(i.company_contact_id) as provider_contact_name,
		prov_contact.work_phone as provider_contact_work_phone,

                paymeth.category_description as payment_method_desc

	from
		im_costs c,
		im_invoices i
                LEFT OUTER JOIN im_categories paymeth ON (i.payment_method_id = paymeth.category_id),
		acs_objects o,
		im_companies cust,
		im_companies prov,
		im_offices oprov,
		users_contact cust_contact,
		users_contact prov_contact
	where
		i.invoice_id = :invoice_id
		and i.invoice_id = c.cost_id
		and i.invoice_id = o.object_id
		and c.customer_id = cust.company_id
		and c.provider_id = prov.company_id
		and oprov.office_id = prov.main_office_id
		and i.company_contact_id = cust_contact.user_id
		and prov.accounting_contact_id = prov_contact.user_id
"]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-ubl.Financial_Document_Not_Found "Didn't find financial document \#%invoice_id%"]
    return
}

if {![db_0or1row cust_office_info "
	select
		ocust.address_line1 as customer_address_line1,
		ocust.address_line2 as customer_address_line2,
		ocust.address_city as customer_address_city,
		ocust.address_state as customer_address_state,
		ocust.address_postal_code as customer_address_postal_code,
		ocust.address_country_code as customer_address_country_code
	from
		im_offices ocust
	where
		ocust.office_id = :cust_office_id
"]} {
    ad_return_complaint 1 [lang::message::lookup "" intranet-ubl.Office_Not_Found "Didn't find customer's office information \#%cust_office_id%"]
    return
}



set invoice_url "/intranet-invoices/view?invoice_id=$invoice_id"


# ---------------------------------------------------------------
# Create the XML
# ---------------------------------------------------------------

set version "1.12"
set view_index 0



# ---------------------------------------------------------------
# Main Document Node

set doc [dom createDocument invoice]
set main_node [$doc documentElement]

$main_node setAttribute xmlns:cbc "urn:oasis:names:specification:ubl:schema:xsd:CommonBasicComponents-1.0" 
$main_node setAttribute	xmlns:cac "urn:oasis:names:specification:ubl:schema:xsd:CommonAggregateComponents-1.0" 
$main_node setAttribute	xmlns:cur "urn:oasis:names:specification:ubl:schema:xsd:CurrencyCode-1.0" 
$main_node setAttribute	xmlns:xsi "http://www.w3.org/2001/XMLSchema-instance" 
$main_node setAttribute	xmlns "urn:oasis:names:specification:ubl:schema:xsd:Invoice-1.0" 
$main_node setAttribute	xsi:schemaLocation "urn:oasis:names:specification:ubl:schema:xsd:Invoice-1.0 ../../xsd/maindoc/UBL-Invoice-1.0.xsd"



$main_node appendXML "<ID>$cost_id</ID>"
$main_node appendXML "<cbc:IssueDate>$issue_date</cbc:IssueDate>"
$main_node appendXML "<TaxPointDate>$issue_date</TaxPointDate>"

$main_node appendXML "	
	<cac:OrderReference>
		<cac:BuyersID>$customer_id</cac:BuyersID>
		<cac:SellersID>$provider_id</cac:SellersID>
		<cbc:IssueDate>$issue_date</cbc:IssueDate>
	</cac:OrderReference>"

$main_node appendXML "
	<cac:BuyerParty>
		<cac:Party>
			<cac:PartyName>
				<cbc:Name>$customer_name</cbc:Name>
			</cac:PartyName>
			<cac:Address>
				<cbc:StreetName>$customer_address_line1 $customer_address_line2</cbc:StreetName>
				<cbc:CityName>$customer_address_city</cbc:CityName>
				<cbc:PostalZone>$customer_address_postal_code</cbc:PostalZone>
				<cac:CountrySubentityCode>$customer_address_state</cac:CountrySubentityCode>
			</cac:Address>
		</cac:Party>
		<cac:AccountsContact>
			<cbc:Name>$customer_contact_name</cbc:Name>
			<cbc:Telephone>$customer_contact_work_phone</cbc:Telephone>
		</cac:AccountsContact>
	</cac:BuyerParty>
"

$main_node appendXML "
	<cac:SellerParty>
		<cac:Party>
			<cac:PartyName>
				<cbc:Name>$provider_name</cbc:Name>
			</cac:PartyName>
			<cac:Address>
				<cbc:StreetName>$provider_address_line1 $provider_address_line2</cbc:StreetName>
				<cbc:CityName>$provider_address_city</cbc:CityName>
				<cbc:PostalZone>$provider_address_postal_code</cbc:PostalZone>
				<cac:CountrySubentityCode>$provider_address_state</cac:CountrySubentityCode>
			</cac:Address>
		</cac:Party>
		<cac:AccountsContact>
			<cbc:Name>$provider_contact_name</cbc:Name>
			<cbc:Telephone>$provider_contact_work_phone</cbc:Telephone>
		</cac:AccountsContact>
	</cac:SellerParty>
"

$main_node appendXML "
	<cac:PaymentTerms>
		<cbc:Note>$payment_method_desc</cbc:Note>
		<cac:ReferenceEventCode>!</cac:ReferenceEventCode>
	</cac:PaymentTerms>
"

ns_return 200 text/xxx [$doc asXML -indent 2 -escapeNonASCII]


