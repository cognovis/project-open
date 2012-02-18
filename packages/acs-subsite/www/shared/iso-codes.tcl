ad_page_contract {
    displays the iso-codes

    @cvs-id $Id: iso-codes.tcl,v 1.2 2010/10/19 20:12:44 po34demo Exp $
} -properties {
    ccodes:multirow
}

if {![db_table_exists countries] } {
    # acs-reference countries not loaded
    set header [ad_header "ISO Codes"]

    ad_return_template iso-codes-no-exist

    return
}

db_multirow ccodes country_codes "select iso, default_name from countries
order by default_name" 

ad_return_template