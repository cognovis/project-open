# revision-add-1.tcl
# choose from (no content, file upload, text entry, xml import)
#    then forward to revision-add-2 or revision-upload.acs

request create
request set_param item_id -datatype integer

# check permissions
content::check_access $item_id cm_write -user_id [User::getID]

set content_type [db_string get_content_type ""]

# flush the sitemap folder listing cache in anticipation 
# of the new item
cms_folder::flush sitemap $item_id

# check for custom create-1 form
if { [file exists [ns_url2file \
	"custom/$content_type/revision-add-1.tcl"]] } {

    template::forward "custom/$content_type/revision-add-1?item_id=$item_id"
}

set name [db_string get_name ""]

# if we have an invalid item_id, then throw error
if { [template::util::is_nil name] } {
    template::request::error bad_item_id \
	    "revision-add-1.tcl - Bad item_id - $item_id"
}



# get the list of associated content methods
set content_methods \
	[content_method::get_content_methods $content_type -get_labels]
set first_method [lindex [lindex $content_methods 0] 1]

# if only one valid content method exists, redirect to revision-add-2
if { [llength $content_methods] == 1 } {
    template::forward "revision-add-2?item_id=$item_id&content_method=$first_method"
}


form create choose_content_method
form section choose_content_method "Choose Content Creation Method"

element create choose_content_method item_id \
	-datatype integer \
	-widget hidden \
	-param

element create choose_content_method content_method \
	-datatype keyword \
	-widget radio \
	-label "Method" \
	-options $content_methods \
	-values $first_method




if { [form is_valid choose_content_method] } {

    form get_values choose_content_method item_id content_method

    # XML imports should forward to revision-upload
    # otherwise pass the content_method to revision-add
    if { [string equal $content_method "xml_import"] } {
	template::forward revision-upload?item_id=$item_id"
    }

    template::forward \
	    "revision-add-2?item_id=$item_id&content_method=$content_method"

}
