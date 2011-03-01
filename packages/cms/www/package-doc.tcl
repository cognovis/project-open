###############
#
# Get documentation about some function
#
##############

request create
request set_param package_name -datatype keyword -optional
request set_param proc_name -datatype keyword -optional

form create func

#if { [util::is_nil package_name] } {
#
#  element create func package_name -widget select -datatype keyword \
#    -options [doc::package_list] -label "Package Name" 
#
#} else {
# 
#  element create func i_package_name -widget inform -datatype keyword \
#    -options [doc::package_list] -label "Package Name" -value $package_name
#
#  element create func package_name -widget hidden -datatype keyword \
#    -options [doc::package_list] -label "Package Name" -value $package_name
#
#  set line_opts [doc::func_list $package_name]
# 
#  element create func proc_name -widget select -datatype text \
#    -label "Function/Procedure Name" \
#    -options $line_opts -values [list $proc_name]
#
#}

element create func package_name -widget select -datatype keyword \
  -options [doc::package_list] -label "Package Name" -param

element create func show -widget hidden -datatype text \
  -label "Show doc ?" -param -optional

if { [form is_valid func] } {
  form get_values func package_name 
}

if { ![util::is_nil package_name] } {

  # List all the functions
  doc::func_multirow $package_name procs

  set url_stub "[ns_conn url]?show=1&"

  if { ![util::is_nil proc_name] } {
    doc::get_proc_doc $proc_name $package_name params tags code \
      -link_url_stub $url_stub
  }
} else {
  set "procs:rowcount" 0
}


