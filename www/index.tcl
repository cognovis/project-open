ad_page_contract {
    Empty redirection index.tcl file
} {

}


set debug "asdf"
intranet_search_pg_files_search_indexer


# set debug [intranet_search_pg_files_index_all]


ad_return_complaint 1 "<pre>\n$debug\n</pre>"
return


