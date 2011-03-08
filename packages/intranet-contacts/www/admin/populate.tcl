ad_page_contract {

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-07-28
    @cvs-id $Id: populate.tcl,v 1.1 2009/02/08 22:28:17 cvs Exp $


} {
    populate_type
    {return_url "index"}
}

contacts::populate::${populate_type} -package_id [ad_conn package_id]
foreach name [ns_cache names util_memoize] {
    ns_cache flush util_memoize $name
} 

ad_returnredirect $return_url