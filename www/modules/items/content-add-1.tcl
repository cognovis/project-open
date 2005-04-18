# content-add-1.tcl
# choose from (file upload, text entry) and forward to content-add-2

request create
request set_param revision_id -datatype integer

db_1row get_revision ""

# permissions check - must have cm_write on the item
content::check_access $item_id cm_write -user_id [User::getID]


# check for custom content-add-1 form
if { [file exists [ns_url2file \
	"custom/$content_type/content-add-1.tcl"]] } {
    template::forward "custom/$content_type/content-add-1?revision_id=$revision_id"
}




# if we have an invalid revision_id, then redirect
if { [template::util::is_nil name] } {
    template::request::error bad_revision_id \
	    "content-add-1.tcl - Bad revision_id - $revision_id"
}


# get associated content methods
set content_methods \
	[content_method::get_content_methods $content_type -get_labels]

# filter out xml_import and no_content
set filtered_content_methods [list]
foreach content_method $content_methods {
    set label  [lindex $content_method 0]
    set method [lindex $content_method 1]
    if { ![string equal $method no_content] && \
	    ![string equal $method xml_import] } {
	lappend filtered_content_methods [list $label $method]
    }
}

# throw an error if there are no content type after filtering out
#   xml_import and no_content
if { [llength $filtered_content_methods] == 0 } {
    template::request::error no_content_methods \
	    "content-add-1.tcl - There are no valid content methods for 
             adding content to a revision."
}

set first_method [lindex [lindex $filtered_content_methods 0] 1]

# immediately forward to content-add-2 if there is only one content
#  method registered (after filtering)
if { [llength $filtered_content_methods] == 1 } {
    template::forward "content-add-2?revision_id=$revision_id&content_method=$first_method"
}



# otherwise, create a form for choosing the content method (filtered)
form create choose_content_method
form section choose_content_method "Choose Content Creation Method"

element create choose_content_method revision_id \
	-datatype integer \
	-widget hidden \
	-param

element create choose_content_method content_method \
	-datatype keyword \
	-widget radio \
	-label "Method" \
	-options $filtered_content_methods \
	-values $first_method




if { [form is_valid choose_content_method] } {

    form get_values choose_content_method revision_id content_method
    template::forward \
	    "content-add-2?revision_id=$revision_id&content_method=$content_method"
}
