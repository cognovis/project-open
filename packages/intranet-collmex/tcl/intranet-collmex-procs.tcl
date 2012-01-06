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
    return [::http::data $token]
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

    # Translation of the country code
    switch $address_country_code {
	"uk" {set address_country_code gb}
    }

    if {$email eq ""} {
	return "ERROR $company_id: missing primary contact for $company_name"
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
    
    set response [split [intranet_collmex::http_post -csv_data $csv_line] ";"]

    set response_info [lindex $response 0]
    if {$response_info eq "MESSAGE"} {
	set response_info [lindex $response 2]
    }

    set return_message ""
    switch $response_info {
	"NEW_OBJECT_ID" {
	    if {$collmex_id eq ""} {
		db_dml update_collmex_id "update im_companies set collmex_id = [lindex $response 1] where company_id = :company_id"
	    } else {
		set return_message "Problem: Collmex ID exists for new company $company_id :: $collmex_id :: new [lindex $response 1]"
	    }
	}
	204002 {
	    set return_message "ERROR $company_id: $response"
	}
	204000 {}
	default {
	    set return_message "ERROR $company_id: $response"
	}
    }

    return $return_message
}
