# A generic error page

request create
request set_param message -datatype text
request set_param return_url -datatype text -value [ns_conn url]
request set_param passthrough -datatype text

# Create the vars datasource
set vars:rowcount 0
upvar 0 vars:rowcount rowcount

foreach pair $passthrough {
  incr vars:rowcount
  upvar 0 vars:$rowcount row
  set row(name) [lindex $pair 0]
  set row(value) [lindex $pair 1]
  set row(rownum) ${vars:rowcount}
}


