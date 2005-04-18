
# @namespace pagination

# Procedures for paginating a datasource

namespace eval pagination {}



ad_proc -public pagination::paginate_query { sql page } {

  @public paginate_query

  Paginates a query

  @author Michael Pih

  @param sql The sql query to paginate
  @param page The current page number

} {

    set rows_per_page [pagination::get_rows_per_page]
    set start_row [expr $rows_per_page*[expr $page-1]+1]

    set query [db_map pq_paginate_query]
    
    return $query
}



ad_proc -private pagination::get_rows_per_page {} {

  @private get_rows_per_page

  Returns the number of rows per page

} {
    return 10
}




ad_proc -public pagination::get_total_pages { sql } {

  @public get_total_pages

  Gets the number of pages returned by a query
  PRE: requires $sql

  @author Michael Pih

  @param db A database handle

} {

    set total_pages [db_string gtp_get_total_pages ""]

    return $total_pages
}



ad_proc -public pagination::page_number_links { page total_pages } {

  @public page_number_links

  Generate HTML for navigating pages of a datasource

  @author Michael Pih

  @param page The current page number
  @param total_pages The total pages returned by the query

} {

    if { $total_pages == 1 } {
	return ""
    }

    set url [ns_conn url]
    set page_vars [ns_getform]
    ns_set update $page_vars total_pages $total_pages

    set rows_per_page [pagination::get_rows_per_page]

    set pagination_html ""

    # append the 'prev' link
    append pagination_html "
      <table border=0 cellspacing=0 cellpadding=4 width=95%>
      <tr bgcolor=\"#ffffff\"><td align=left width=10%>"
    if { $page > 1 } {
	ns_set update $page_vars page [expr $page-1]
	set url_vars [pagination::ns_set_to_url_vars $page_vars]

	append pagination_html "
	  <a href=\"$url?$url_vars\">&lt;&lt; Prev </a>"
    } else {
	append pagination_html "&nbsp;"
    }
    append pagination_html "</td><td align=center width=80%>"

    # append page number links for all pages except for this page
    for { set i 1 } { $i <= $total_pages } { incr i } {
	if { $i == $page } {
	    append pagination_html " $page "
	} else {
	    ns_set update $page_vars page $i
	    set url_vars [pagination::ns_set_to_url_vars $page_vars]
	    append pagination_html "
	      <a href=\"$url?$url_vars\">$i</a>"
	}
    }
    append pagination_html "</td><td align=right width=10%>"

    # append the 'next' link
    if { $page < $total_pages } {
	ns_set update $page_vars page [expr $page+1]
	set url_vars [pagination::ns_set_to_url_vars $page_vars]

	append pagination_html "
	  <a href=\"$url?$url_vars\"> Next &gt;&gt;</a>"
    } else {
	append pagination_html "&nbsp;"
    }
    append pagination_html "</td></tr></table>"

    return $pagination_html
}



ad_proc -private pagination::ns_set_to_url_vars { set_id } {

  @private ns_set_to_url_vars

  Converts an ns_set into a list of url variables

  @author Michael Pih

  @param set_id The set id

} {
    set url_vars ""
    set size [ns_set size $set_id]
    for { set i 0 } { $i < $size } { incr i } {
	set key [ns_set key $set_id $i]
	set value [ns_set get $set_id $key]
	append url_vars "$key=$value"
	if { $i < [expr $size-1] } {
	    append url_vars "&"
	}
    }
    return $url_vars
}
