# Display and paginate the search results

request create
request set_param id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value search
request set_param parent_id -datatype keyword -optional

request set_param sql_query -datatype text
request set_param total_results -datatype integer
request set_param start_row -datatype integer -optional -value 1

set query_key "[User::getID].search.sql_query"
if { ![nsv_exists browser_state $query_key] } {
  set sql_query ""
} else {
  set sql_query [nsv_get browser_state $query_key]
}

set passthrough "id=$id&mount_point=$mount_point&parent_id=$parent_id&total_results=$total_results"

set package_url [ad_conn package_url]
set clipboardfloats_p [clipboard::floats_p]

if { ![util::is_nil sql_query] } {

  set clip [clipboard::parse_cookie]

  # In the future, get this from the db prefs
  set rows_per_page 10

  # Perform the query, get results
  db_multirow -extend offset results get_results "" {
    clipboard::get_bookmark_icon $clip $mount_point $item_id
    set offset [expr $rownum + $start_row - 1]
  }

  # Prepare a multirow datasource for pages
  set page_count [expr $total_results / $rows_per_page]
  if { [expr $total_results % $rows_per_page] > 0 } {
    incr page_count
  }

  if { $page_count > 10 } {
    set page_count 10
  }

  for { set i 0 } { $i <= $page_count } { incr i } {
    set index [expr $i + 1]
    upvar 0 "pages:$index" row
    set row(rownum) $index
    set row(label) $index
    set row(url) "search-results?$passthrough&start_row=[expr [expr $i * $rows_per_page] + 1]"
  }
  set pages:rowcount $page_count

  set current_page [expr [expr $start_row / $rows_per_page] + 1]
  set next_row [expr $start_row + $rows_per_page]
  set prev_row [expr $start_row - $rows_per_page]
}



