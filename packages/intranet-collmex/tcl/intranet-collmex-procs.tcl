# packages/intranet-collmex/tcl/intranet-collmex-procs.tcl

## Copyright (c) 2011, cognovís GmbH, Hamburg, Germany
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as published by
# the Free Software Foundation, either version 3 of the License, or
# (at your option) any later version.
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see
# <http://www.gnu.org/licenses/>.
# 

ad_library {
    
    Procedure to interact with collmex
    
    @author <yourname> (<your email>)
    @creation-date 2012-01-04
    @cvs-id $Id$
}

namespace eval intranet_collmex {}
package require tls

ad_proc -public intranet_collmex::http_post {
    {-csv_data ""}
} {
} {
    # Make sure we can use HTTPS
    ::http::register https 443 ::tls::socket

    set customer_nr [parameter::get_from_package_key -package_key intranet-collmex -parameter CollmexKundenNr]
    set login [parameter::get_from_package_key -package_key intranet-collmex -parameter Login]
    set password  [parameter::get_from_package_key -package_key intranet-collmex -parameter Password]

    set data "LOGIN;$login;$password\n${csv_data}\n"
    set token [::http::geturl https://www.collmex.de/cgi-bin/cgi.exe?${customer_nr},0,data_exchange \
		     -type "text/csv" \
		   -query $data]

    ns_log Notice "Collmex Query: $data"
    set response [::http::data $token]
    ns_log Notice "Collmex:: $response"
    set meldungstyp [lindex [split $response ";"] 1]
    switch $meldungstyp {
	S {
	    return $response
	}
	W {
	    # Warning Mail
	    acs_mail_lite::send -send_immediately -to_addr [ad_admin_owner] -from_addr [ad_admin_owner] -subject "Collmex Warning" -body "There was a warning in collmex, but the call was successful. <p /> \
<br />Called: $csv_data \
<br />Reponse $response" -mime_type "text/html"
	    return $response
	}
	E {
	    # Error Mail
	    ns_log Error "Error in Collmex: $response"
	    acs_mail_lite::send -send_immediately -to_addr [ad_admin_owner] -from_addr [ad_admin_owner] -subject "Collmex Error" -body "There was a error in collmex, data is not transferred.<p /> \
<br />Called: $csv_data \
<br />Reponse $response" -mime_type "text/html"
	    return "-1"
	}
	default {
	    return $response
	}
    }
}

ad_proc -public intranet_collmex::update_company {
    -company_id
    -customer:boolean
} {
    send the company to collmex for update

    use field description from http://www.collmex.de/cgi-bin/cgi.exe?1005,1,help,daten_importieren_kunde
} {
    
    if {$customer_p} {
	set Satzart "CMXKND"
    } else {
	set Satzart "CMXLIF"
    }

    db_1row customer_info {
	select *
        from im_offices o, im_companies c
	left outer join (select * from persons p, parties pa where p.person_id = pa.party_id) po  
	   on c.primary_contact_id = po.person_id 
	where c.main_office_id = o.office_id
	and c.company_id = :company_id
    } 

    if {$email eq "" && $address_country_code eq "" && $address_line1 eq ""} {
	return
    }

    # Translation of the country code
    switch $address_country_code {
	"uk" {set address_country_code gb}
	""   {set address_country_code de} ; # default country code germany
    }

    if {$email eq ""} {
	set email "[parameter::get_from_package_key -package_key "acs-kernel" -parameter "HostAdministrator"]"
    }
    
    set csv_line "$Satzart"
    
    if {[exists_and_not_null collmex_id]} {
	append csv_line ";$collmex_id"
    } else {
	append csv_line ";"
    }
    
    append csv_line ";1" ; # Firma Nr (internal)
    append csv_line ";" ; # Anrede
    append csv_line ";" ; # Title
    append csv_line ";\"[im_csv_duplicate_double_quotes $first_names]\"" ; # Vorname
    append csv_line ";\"[im_csv_duplicate_double_quotes $last_name]\"" ;# Name
    append csv_line ";\"[im_csv_duplicate_double_quotes $company_name]\"" ; # Firma
    append csv_line ";\"[im_csv_duplicate_double_quotes $title]\"" ; # Abteilung
    
    append address_line1 "\n $address_line2"
    append csv_line ";\"[im_csv_duplicate_double_quotes $address_line1]\"" ; # Straße
    
    append csv_line ";\"[im_csv_duplicate_double_quotes $address_postal_code]\"" ; # PLZ
    append csv_line ";\"[im_csv_duplicate_double_quotes $address_city]\"" ; # Ort
    append csv_line ";\"[im_csv_duplicate_double_quotes $note]\"" ; # Bemerkung
    append csv_line ";0" ; # Inaktiv
    append csv_line ";\"[im_csv_duplicate_double_quotes $address_country_code]\"" ; # Land
    append csv_line ";\"[im_csv_duplicate_double_quotes $phone]\"" ; # Telefon
    append csv_line ";\"[im_csv_duplicate_double_quotes $fax]\"" ; # Telefax
    append csv_line ";\"[im_csv_duplicate_double_quotes $email]\"" ; # E-Mail
    append csv_line ";\"[im_csv_duplicate_double_quotes $bank_account_nr]\"" ; # Kontonr
    append csv_line ";\"[im_csv_duplicate_double_quotes $bank_routing_nr]\"" ; # Blz
    append csv_line ";\"[im_csv_duplicate_double_quotes $iban]\"" ; # Iban
    append csv_line ";\"[im_csv_duplicate_double_quotes $bic]\"" ; # Bic
    append csv_line ";\"[im_csv_duplicate_double_quotes $bank_name]\"" ; # Bankname
    append csv_line ";\"[im_csv_duplicate_double_quotes $tax_number]\"" ; # Steuernummer
    append csv_line ";\"[im_csv_duplicate_double_quotes $vat_number]\"" ; # USt.IdNr
    append csv_line ";6" ; # Zahlungsbedingung
    
    if {$customer_p} {
	append csv_line ";" ; # Rabattgruppe
    }
    
    append csv_line ";" ; # Lieferbedingung
    append csv_line ";" ; # Lieferbedingung Zusatz
    append csv_line ";1" ; # Ausgabemedium
    append csv_line ";" ; # Kontoinhaber
    append csv_line ";" ; # Adressgruppe
    
    if {$customer_p} {
	append csv_line ";" ; # eBay-Mitgliedsname
	append csv_line ";" ; # Preisgruppe
	append csv_line ";" ; # Währung (ISO-Codes)
	append csv_line ";" ; # Vermittler
	append csv_line ";" ; # Kostenstelle
	append csv_line ";" ; # Wiedervorlage am
	append csv_line ";" ; # Liefersperre
	append csv_line ";" ; # Baudienstleister
	append csv_line ";" ; # Lief-Nr. bei Kunde
	append csv_line ";" ; # Ausgabesprache
	append csv_line ";" ; # CC
	append csv_line ";" ; # Telefon2
    } else {
	append csv_line ";" ; # Kundennummer beim Lieferanten
	append csv_line ";" ; # Währung (ISO-Codes)
	append csv_line ";" ; # Telefon2
	append csv_line ";" ; # Ausgabesprache
    }
    
    set response [intranet_collmex::http_post -csv_data $csv_line]
    if {$response != "-1"} {
	set response [split $response ";"]
	if {[lindex $response 0] == "NEW_OBJECT_ID"} {
	    ns_log Notice "New Customer:: [lindex $response 1]"
	    # This seems to be a new customer
	    if {$collmex_id eq ""} {
		db_dml update_collmex_id "update im_companies set collmex_id = [lindex $response 1] where company_id = :company_id"
		set return_message [lindex $response 1]
	    } else {
		set return_message "Problem: Collmex ID exists for new company $company_id :: $collmex_id :: new [lindex $response 1]"
		acs_mail_lite::send -send_immediately -to_addr [ad_admin_owner] -from_addr [ad_admin_owner] -subject "Collmex ID already present in project-open" -body "$return_message"
	    }
	}
    }
}

ad_proc -public intranet_collmex::update_provider_bill {
    -invoice_id
    -storno:boolean
} {
    send the provider bill to collmex
} {
    # Get all the invoice information
    db_1row invoice_data {
	select collmex_id,to_char(effective_date,'YYYYMMDD') as invoice_date, invoice_nr, 
	round(vat,0) as vat, round(amount,2) as netto, c.company_id, address_country_code, ca.aux_int2 as konto, cc.collmex_kostenstelle as kostenstelle
	from im_invoices i, im_costs ci, im_companies c, im_offices o, im_categories ca, im_cost_centers cc
	where c.company_id = ci.provider_id 
	and c.main_office_id = o.office_id
	and ci.cost_id = i.invoice_id 
	and ca.category_id = c.tax_classification
        and cc.cost_center_id = ci.cost_center_id
	and i.invoice_id = :invoice_id
    }

    regsub -all {\.} $netto {,} netto

    set csv_line "CMXLRN"

    if {$collmex_id eq ""} {
	set collmex_id [intranet_collmex::update_company -company_id $company_id]
    }

    append csv_line ";$collmex_id" ; # Lieferantennummer
    append csv_line ";1" ; # Firma Nr
    append csv_line ";$invoice_date" ; # Rechnungsdatum
    append csv_line ";$invoice_nr" ; # Rechnungsnummer

    if {$konto eq ""} {
	set konto [parameter::get_from_package_key -package_key "intranet-collmex" -parameter "KontoBill"]
    }

    # Find if the provide is from germany and has vat.
    if {$vat eq 19} {
	append csv_line ";\"[im_csv_duplicate_double_quotes $netto]\"" ; # Nettobetrag voller Umsatzsteuersatz
    } else {
	append csv_line ";"
    }
    append csv_line ";" ; # Steuer zum vollen Umsatzsteuersatz
    append csv_line ";" ; # Nettobetrag halber Umsatzsteuersatz
    append csv_line ";" ; # Steuer zum halben Umsatzsteuersatz
    if {$vat eq 19} {
	append csv_line ";"
	append csv_line ";"
    } else {
	append csv_line ";$konto" ; # Sonstige Umsätze: Konto Nr.
	append csv_line ";\"[im_csv_duplicate_double_quotes $netto]\"" ; # Sonstige Umsätze: Betrag
    }

    append csv_line ";\"EUR\"" ; # Währung (ISO-Codes)
    append csv_line ";" ; # Gegenkonto (1600 per default)
    append csv_line ";" ; # Gutschrift
    append csv_line ";" ; # Belegtext
    append csv_line ";6" ; # Zahlungsbedingung
    if {$vat eq 19} {
	append csv_line ";$konto" ; # KontoNr voller Umsatzsteuersatz
    } else {
	append csv_line ";"
    }
    append csv_line ";" ; # KontoNr halber Umsatzsteuersatz
    if {$storno_p} {
	append csv_line ";1" ; # Storno
    } else {
	append csv_line ";" ; # Storno
    }
    append csv_line ";$kostenstelle" ; # Kostenstelle

    set response [intranet_collmex::http_post -csv_data $csv_line]
}

ad_proc -public intranet_collmex::update_customer_invoice {
    -invoice_id
    -storno:boolean
} {
    send the customer invoice to collmex
} {
    # Get all the invoice information
    db_1row invoice_data {
	select collmex_id,to_char(effective_date,'YYYYMMDD') as invoice_date, invoice_nr, 
	  round(vat,0) as vat, round(amount,2) as netto, c.company_id, address_country_code, ca.aux_int2 as konto, cc.collmex_kostenstelle as kostenstelle
	from im_invoices i, im_costs ci, im_companies c, im_offices o, im_categories ca, im_cost_centers cc
	where c.company_id = ci.customer_id 
	and c.main_office_id = o.office_id
	and ci.cost_id = i.invoice_id 
        and cc.cost_center_id = ci.cost_center_id
        and ca.category_id = c.tax_classification
	and i.invoice_id = :invoice_id
    }

    regsub -all {\.} $netto {,} netto

    set csv_line "CMXUMS"
    if {$collmex_id eq ""} {
	set collmex_id [intranet_collmex::update_company -company_id $company_id -customer]
    }
	
    append csv_line ";$collmex_id" ; # Lieferantennummer
    append csv_line ";1" ; # Firma Nr
    append csv_line ";$invoice_date" ; # Rechnungsdatum
    append csv_line ";$invoice_nr" ; # Rechnungsnummer

    if {$konto eq ""} {
	set konto [parameter::get_from_package_key -package_key "intranet-collmex" -parameter "KontoInvoice"]
    }

    # Find if the provide is from germany and has vat.
    if {$vat eq 19} {
	append csv_line ";\"[im_csv_duplicate_double_quotes $netto]\"" ; # Nettobetrag voller Umsatzsteuersatz
    } else {
	append csv_line ";"
    }
    
    append csv_line ";" ; # Steuer zum vollen Umsatzsteuersatz
    append csv_line ";" ; # Nettobetrag halber Umsatzsteuersatz
    append csv_line ";" ; # Steuer zum halben Umsatzsteuersatz
    append csv_line ";" ; # Umsätze Innergemeinschaftliche Lieferung
    append csv_line ";" ; # Umsätze Export
    append csv_line ";$konto" ; # Steuerfreie Erloese Konto
    if {$vat eq 19} {
	append csv_line ";" ; # Hat VAT => Nicht Steuerfrei
    } else {
	append csv_line ";\"[im_csv_duplicate_double_quotes $netto]\""; # Steuerfrei Betrag
    }
    append csv_line ";\"EUR\"" ; # Währung (ISO-Codes)
    append csv_line ";" ; # Gegenkonto
    append csv_line ";0" ; # Rechnungsart
    append csv_line ";" ; # Belegtext
    append csv_line ";6" ; # Zahlungsbedingung
    if {$vat eq 19} {
	append csv_line ";$konto" ; # KontoNr voller Umsatzsteuersatz
    } else {
	append csv_line ";"
    }
    append csv_line ";" ; # KontoNr halber Umsatzsteuersatz
    append csv_line ";" ; # reserviert
    append csv_line ";" ; # reserviert
    if {$storno_p} {
	append csv_line ";1" ; # Storno
    } else {
	append csv_line ";" ; # Storno
    }
    append csv_line ";" ; # Schlussrechnung
    append csv_line ";" ; # Erloesart
    append csv_line ";\"projop\"" ; # Systemname
    append csv_line ";" ; # Verrechnen mit Rechnugnsnummer fuer gutschrift
    append csv_line ";" ; # Kostenstelle
    
    set response [intranet_collmex::http_post -csv_data $csv_line]    
}


ad_proc -public intranet_collmex::invoice_payment_get {
    {-invoice_id ""}
    -all:boolean
} {
    get a list of invoice payments from collmex
} {
    
    set csv_line "INVOICE_PAYMENT_GET;1"
    if {$invoice_id ne ""} {
	set invoice_nr [db_string invoice_nr "select invoice_nr from im_invoices where invoice_id = :invoice_id" -default ""]
	append csv_line ";${invoice_nr}"
    } else {
	append csv_line ";"
    }
    if {$all_p} {
	append csv_line ";"
    } else {
	append csv_line ";1"
    }
    append csv_line ";\"projop\"" ; # Systemname
    
    # Now get the lines from Collmex
    set lines [split [intranet_collmex::http_post -csv_data $csv_line] "\n"]

    set return_html ""
    foreach line $lines {
	# Find out if it actually is a payment line
	set line_items [split $line ";"]
	if {[lindex $line_items 0] eq "INVOICE_PAYMENT"} {
	    set collmex_id  "[lindex $line_items 5]-[lindex $line_items 6]-[lindex $line_items 7]"
	    set date  [lindex $line_items 2] ; # Datum
	    set amount  [lindex $line_items 4] ; # Actually paid amount
	    set invoice_nr [lindex $line_items 1]
	    regsub -all {,} $amount {.} amount
	    # Check if we have this id already for a payment
	    if {[db_string payment_id "select payment_id from im_payments where collmex_id = :collmex_id" -default ""] ne ""} {
		db_dml update "update im_payments set received_date = to_date(:date,'YYYYMMDD'), amount = :amount where collmex_id = :collmex_id"
		append return_html "$invoice_nr <br> $amount :: $collmex_id"
	    } else {
		# Find the invoice_id
		set invoice_id [db_string invoice_id "select invoice_id from im_invoices where invoice_nr = :invoice_nr" -default ""]
		if {$invoice_id ne "" && $collmex_id ne "--"} {
		    # Lets record the payment
		    set payment_id [im_payment_create_payment -cost_id $invoice_id]
		    db_dml update "update im_payments set received_date = to_date(:date,'YYYYMMDD'), amount = :amount, collmex_id = :collmex_id where payment_id = :payment_id"
		}
	    }
	} 	    
    }
    return 1
}