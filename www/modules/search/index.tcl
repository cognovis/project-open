request create
request set_param id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value search
request set_param parent_id -datatype keyword -optional


# Get the tabulated list of content types
set content_types [cm::modules::types::getTypesTree]

# Get a list of mime-types
set mime_types [db_list_of_lists get_mime_types ""]

form create search -html { name search method post }

form section search "Search Parameters"

element create search content_type \
  -label "Content Type" -datatype keyword -widget select -optional \
  -options $content_types

element create search keywords \
  -label "Keywords" -datatype text -widget text \
  -html { size 40 }

element create search fields \
  -label "Search in" -datatype text -widget checkbox \
  -options { {Title title} {Description description} {Content content} } \
  -values { title }

element create search mime_type \
  -label "Mime Type" -datatype text -widget select -optional \
  -options [concat [list [list "--" ""]] $mime_types] 

element create search which_revisions \
  -label "Which Revisions" -datatype keyword -widget radio \
  -options { {{Search only the live revisions} live} {{Search all revisions} all}} \
  -values { live }

form section search "Date Range"

element create search start_date \
  -label "Start Date" -datatype date -widget date \
  -format "YYYY/MM/DD HH24:MI" -year_interval { 2000 2005 1 } -optional -help

element create search end_date \
  -label "End Date" -datatype date -widget date \
  -format "YYYY/MM/DD HH24:MI" -year_interval { 2000 2005 1 } -optional -help

# Assemble the query and redirect to the result page if the
# query is valid
if { [form is_valid search] } {

  form get_values search content_type keywords mime_type which_revisions start_date end_date

  # Assemble the literal query, no bind vars, since the keywords make it pretty
  # much unpredictable

  # Create the contains clause, the within clause
  set word_list [split $keywords " "]
  set inter_clause ""
  set the_or ""
  set within_clause ""
  foreach word $word_list {
    append inter_clause "${the_or}%[string tolower $word]%"
    append within_clause "${the_or}%[string tolower $word]% within \$field"
    #append within_clause [db_map within_clause]
    set the_or ","
  }

  set attrs_table ""
  set attrs_where ""

  # Use this clause for each of the selected fields
  set contains_clause ""
  set score_expr ""
  set the_or "" 
  set the_plus ""
  set label 10
  foreach field [element get_values search fields] {
    if { ![string equal $field content] } {
      set search_clause [subst $within_clause]
      set column_name "ra.attributes"
      set attrs_table ", cr_revision_attributes ra"
      set attrs_where "\n    and ra.revision_id = r.revision_id"
    } else {
      set search_clause $inter_clause
      set column_name "r.content"
    }
    append contains_clause [db_map contains_clause]
    set the_or " or "
    append score_expr [db_map score_expr]
    set the_plus " +"
    incr label 10
  }

  # Build the basic query
  set live_p [string equal $which_revisions live]
  set sql_query [db_map sql_query]

  # Append other search parameters to the query

  if { $live_p } {
    append sql_query [db_map live_revision]
  } else {
    append sql_query "\n    and r.item_id = i.item_id"
  }

  if { ![util::is_nil mime_type] } {
    append sql_query "\n    and r.mime_type = '$mime_type'"
  }

  if { ![util::is_nil content_type] } {
    append sql_query "\n    and i.content_type = '$content_type'"
  }

  if { ![util::is_nil start_date] && ![util::is_nil end_date] } {
    append sql_query "\n    and (r.publish_date between "
    append sql_query [util::date get_property sql_date $start_date]
    append sql_query " and "
    append sql_query [util::date get_property sql_date $end_date]
    append sql_query ")"
  }

  ns_log notice $sql_query

  # Perform the query and get the total results
  set total_results [db_string get_results ""]

  # Memoize the query - can't pass it through :-(
  nsv_set browser_state "[User::getID].search.sql_query" $sql_query

  template::forward "search-results?total_results=$total_results&id=$id&parent_id=$parent_id"

} 









