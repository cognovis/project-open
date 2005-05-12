ad_page_contract {
    @author Neophytos Demetriou <k2pts@cytanet.com.cy>
    @author Frank Bergmann <frank.bergmann@project-open.com>
    @creation-date May 20th, 2005
    @cvs-id $Id$
} {
    q:notnull,trim
    {t:trim ""}
    {offset:integer 0}
    {results_per_page:integer 0}
} -errors {
    q:notnull {[_ search.lt_You_must_specify_some].}
}

set page_title "Search Results"
set package_id [ad_conn package_id]
set package_url [ad_conn package_url]
set package_url_with_extras $package_url
set context [list]
set context_base_url $package_url
set user_id [ad_conn user_id]

if { $results_per_page <= 0} {
    set results_per_page [ad_parameter -package_id $package_id SearchResultsPerPage]
} else {
    set results_per_page $results_per_page
}


set q [string tolower $q]
set urlencoded_query [ad_urlencode $q]
if { $offset < 0 } { set offset 0 }
set t0 [clock clicks -milliseconds]

set sql "
	select	*
	from	im_search_objects
	where	fti @@ 'test'::tsquery
"

set low 0
set high 0

set count 0
set result_html ""
db_foreach full_text_query $sql {
    append result_html "
      <tr>
	<td>
	  $object_id - $object_type_id - $biz_object_id
	</td>
      </tr>
"
    incr count
}


set url_advanced_search ""
append url_advanced_search "advanced-search?q=${urlencoded_query}"
if { $results_per_page > 0 } { append url_advanced_search "&results_per_page=${results_per_page}" }



set tend [clock clicks -milliseconds]
set elapsed [format "%.02f" [expr double(abs($tend - $t0)) / 1000.0]]

set and_queries_notice_p 0
set nstopwords 0
set query $q
set nquery [llength $q]


set from_result_page 1
set current_result_page [expr ($offset / $results_per_page) + 1]
set to_result_page [expr ceil(double($count) / double($results_per_page))]

ad_return_template
return




template::multirow create searchresult title_summary txt_summary url_one

for { set __i 0 } { $__i < [expr $high - $low +1] } { incr __i } {

    set object_id [lindex $result(ids) $__i]
    set object_type [acs_object_type $object_id]
    array set datasource [acs_sc_call FtsContentProvider datasource [list $object_id] $object_type]
    search_content_get txt $datasource(content) $datasource(mime) $datasource(storage_type)
    set title_summary [acs_sc_call FtsEngineDriver summary [list $q $datasource(title)] $driver]
    set txt_summary [acs_sc_call FtsEngineDriver summary [list $q $txt] $driver]
    set url_one [acs_sc_call FtsContentProvider url [list $object_id] $object_type]
    
    # Replace the "index" with ETP as this is not needed for accessing the page
    if {[string equal $object_type "etp_page_revision"]} {
	set url_one [string trimright $url_one "index"]
    }
	template::multirow append searchresult $title_summary $txt_summary $url_one
}



set url_previous ""
set url_next ""
append url_previous "search?q=${urlencoded_query}"
append url_next "search?q=${urlencoded_query}"
if { [expr $current_result_page - 1] > $from_result_page } { 
    append url_previous "&offset=[expr ($current_result_page - 2) * $limit]"
}
if { $current_result_page < $to_result_page } { 
    append url_next "&offset=[expr $current_result_page * $limit]"
}
if { $results_per_page > 0 } {
    append url_previous "&results_per_page=$results_per_page"
    append url_next "&results_per_page=$results_per_page"
}


set items [list]
set links [list]
set values [list]
for { set __i $from_result_page } { $__i <= $to_result_page} { incr __i } {
    set link ""
    append link "search?q=${urlencoded_query}"
    if { $__i > 1 } { append link "&offset=[expr ($__i - 1) * $limit]" }
    if { $results_per_page > 0 } { append link "&results_per_page=$results_per_page" }

    lappend items $__i
    lappend links $link
    lappend values $__i
}

set search_the_web [ad_parameter -package_id $package_id SearchTheWeb]
if [llength $search_the_web] {
    set stw ""
    foreach {url site} $search_the_web {
	append stw "<a href=[format $url $urlencoded_query]>$site</a> "
    }
}

set choice_bar [search_choice_bar $items $links $values $current_result_page]

