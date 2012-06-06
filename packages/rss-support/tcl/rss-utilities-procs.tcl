ad_library { 
    RSS support procs 
    
    @author Andrew Grumet (aegrumet@alum.mit.edu)
    @author Jerry Asher (jerry@theashergroup.com)
    @author Dave Bauer (dave@thedesignexperience.org)

    @creation-date Fri Oct 26 11:43:26 2001
    @cvs-id $Id$
}


ad_proc -public rss_package_id {} {
    <pre>
    # Returns the package_id for rss if it is rss is mounted.
    # Returns 0 otherwise.
    </pre>
} {
    if ![db_0or1row get_package_id {}] {
	return 0
    } else {
	return $package_id
    }
}   

ad_proc -public rss_package_url {} {
    <pre>
    # Returns the rss package url if it is mounted.
    # Returns the empty string otherwise.
    </pre>
} {
    set package_id [rss_package_id]
    return [db_string rss_url {} -default ""]

}

ad_proc -public rss_first_url_for_package_id {
    package_id
} {
    Finds the first site node (ordered by node_id)
    associated with package_id and returns the
    relative url for that node.  Returns empty string
    if the package is not mounted.
} {
    return [util_memoize "rss_first_url_for_package_id_helper $package_id"]
}

ad_proc -private rss_first_url_for_package_id_helper {
    package_id
} {
    Does the actual work for rss_first_url_for_package_id.
} {
    set url ""

    if [db_0or1row first_node_id {}] {
	db_foreach url_parts {} {
	    append url ${name}
	}
    }

    return $url
}
