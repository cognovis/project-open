# content-method-links.tcl
# Display content method links

request create
request set_param item_id      -datatype integer
request set_param content_type -datatype keyword
request set_param target_url   -datatype text -value ""


# default target_url
if { [template::util::is_nil target_url] } {
    set target_url "revision-add-2"
}


# get the list of associated content methods
set content_methods \
	[content_method::get_content_methods $content_type -get_labels]
set content_method_count [llength $content_methods]


# convert the list into a datasource
multirow create content_methods_ds label method
set i 1
foreach one_method $content_methods {
    set label  [lindex $one_method 0]
    set method [lindex $one_method 1]

    multirow append content_methods_ds $label $method
    incr i
}
