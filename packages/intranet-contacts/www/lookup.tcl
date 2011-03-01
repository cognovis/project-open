ad_page_contract {
    Lookup contact names

    @author Malte Sussdorff (malte.sussdorff@cognovis.de)
    @creation-date 2006-12-17
    @cvs-id $Id: lookup.tcl,v 1.1 2009/02/08 22:28:17 cvs Exp $
} {
    {query ""}
}

if {$query eq ""} {
    set result "no_result"
} else {
    set result ""
    set sql "select first_names, last_name,person_id from persons where lower(first_names) like lower('%$query%') or lower(last_name) like lower('%$query%')"
    db_foreach contacts "$sql" {
	append result "<a href=\"/intranet/contacts/$person_id\">$first_names $last_name</a><br>"
    }
}