ad_library {

    Initialization for intranet-search-pg-files module
    
    @author Frank Bergmann (frank.bergmann@project-open.com)
    @creation-date 10 November, 2006
    @cvs-id $Id: intranet-search-pg-files-init.tcl,v 1.4 2006/11/09 17:50:53 cvs Exp $

}

# Initialize the search "semaphore" to 0.
# There should be only one thread indexing files at a time...
nsv_set intranet_search_pg_files search_indexer_p 0

# Check for changed files every X minutes
ad_schedule_proc -thread t [parameter::get_from_package_key -package_key intranet-search-pg-files -parameter SearchIndexerInterval -default 600 ] intranet_search_pg_files_search_indexer

