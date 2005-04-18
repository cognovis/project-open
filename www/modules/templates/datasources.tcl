# Load the TCL file for the template and parse out the datasource
# documentation

request create
request set_param template_id -datatype integer

# Get the name for the template's TCL file
set url [item::get_url $template_id]

if { [template::util::is_nil url] } {
  set template_exists f
  return
}

set template_exists t

set tcl_stub "${url}.tcl"

# In the future, we may have many roots !
set template_root [publish::get_template_root]
set tcl_file [ns_normalizepath "/$template_root/${url}.tcl"]

# Load and process the file
if { ![file exists $tcl_file] } {
  set file_exists f
  set code_exists f
  return
} 

set file_exists t
set code [template::util::read_file $tcl_file]

if { [template::util::is_nil code] } {
  set code_exists f
}

set code_exists t

set datasource_names [template::get_datasources $code]

# Attempt to auto-generate any missing datasources
# NOTE: This should really be a proc (or multiple procs), but
# ATS is frozen now...

upvar 0 "datasources:rowcount" rowcount  

# Concatenate split lines
regsub -all -- {\\\n} $code " " line_code

set query_exp \
  {query +([a-zA-Z0-9_]+) +(onevalue|onelist|onerow|multirow) +[^ ]+}
set multi_exp \
  {multirow +create +([a-zA-Z0-9_]+) +(.*)}

foreach line [split $line_code "\n"] {

  set name ""

  # Try looking for "query ..." or "multirow create..."
  if { [regexp -nocase -- $query_exp $line match name type] } {
    set cols [list "-"]
  } elseif { [regexp -nocase -- $multi_exp $line match name cols] } {
    set type "multirow"
  }

  # If found, try to add the datasource
  if { ![template::util::is_nil name] } {

    # See if the datasource exists already
    set found 0
    for { set j 1} { $j <= $rowcount } { incr j } {
      template::multirow get datasources $j
      if { [string equal $datasources(name) $name] } {
	set found 1
	break
      }
    }

    # If the datasource does not exist, add it
    if { !$found } {
      foreach col $cols {
	incr rowcount
	upvar 0 "datasources:$rowcount" datasources
	set datasources(rownum)         $rowcount
	set datasources(name)           $name
	set datasources(structure)      $type
	set datasources(comment)        "Auto-generated from query"
	set datasources(is_auto)        t
        set datasources(column_name)    $col
        set datasources(column_comment) "<font color=gray>unknown</font>"
        set datasources(input_name)     $col
        set datasources(input_type)     "<font color=gray>unknown</font>"
        set datasources(input_comment)  "<font color=gray>unknown</font>"
      }
    }
  }
}