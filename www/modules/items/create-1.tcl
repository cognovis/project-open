# create-1.tcl
# choose from (no content, file upload, text entry, xml import)
#    then forward to create-2 or revision-upload

request create
request set_param content_type -datatype keyword -value "content_revision"
request set_param mount_point  -datatype keyword -value "sitemap"
request set_param parent_id    -datatype integer -optional

set flush_parent_id $parent_id

# Manually set the value since the templating system is still broken in 
# the -value flag
if { [template::util::is_nil parent_id] } {
  set parent_id [cm::modules::${mount_point}::getRootFolderID]
}

# permissions check - need cm_new on the parent item
content::check_access $parent_id cm_new -user_id [User::getID]

# flush the sitemap folder listing cache in anticipation 
# of the new item
cms_folder::flush sitemap $flush_parent_id

# check for custom create-1 form
if { [file exists [ns_url2file \
	"custom/$content_type/create-1.tcl"]] } {

    template::forward "custom/$content_type/create-1?content_type=$content_type&mount_point=$mount_point&parent_id=$parent_id"
}


set content_type_name [db_string get_content_typ_name ""]

if { [template::util::is_nil content_type_name] } {
    template::request::error bad_content_type \
	    "create-1.tcl - Bad content type - $content_type"
}


# get the list of associated content methods
set content_methods \
	[content_method::get_content_methods $content_type -get_labels]
set first_method [lindex [lindex $content_methods 0] 1]
set first_label  [lindex [lindex $content_methods 0] 0]

form create choose_content_method
form section choose_content_method "Choose Content Creation Method"

element create choose_content_method parent_id \
	-datatype integer \
	-widget hidden \
	-value $parent_id

element create choose_content_method content_type \
	-datatype keyword \
	-widget hidden \
	-value $content_type


# if there is only one valid content_method, don't show the radio buttons
#    and instead use a hidden widget and inform widget for content_method
if { [llength $content_methods] == 1 } {

    element create choose_content_method content_method \
	    -datatype keyword \
	    -widget hidden \
	    -value $first_method

    element create choose_content_method content_method_inform \
	    -widget inform \
	    -label "Method" \
	    -value $first_label
} else {

    element create choose_content_method content_method \
	    -datatype keyword \
	    -widget radio \
	    -label "Method" \
	    -options $content_methods \
	    -values $first_method
}


# Add the relation tag element
content::add_child_relation_element choose_content_method -section

# if there is no relation tag necessary and there is only one content method,
#    then forward to create-2 with that content method
if { ![element exists choose_content_method relation_tag] && \
	[llength $content_methods] == 1 } {
    template::forward "create-2?parent_id=$parent_id&content_type=$content_type&content_method=$first_method"
}


# Process the form
if { [form is_valid choose_content_method] } {

    form get_values choose_content_method \
	    content_type parent_id content_method 

    if { [element exists choose_content_method relation_tag] } {
	set relation_tag \
		[element get_value choose_content_method relation_tag]
    }
    if { [util::is_nil relation_tag] } {
	set relation_tag ""
    }



    # XML imports should forward to revision-upload
    # otherwise pass the content_method to revision-add
    if { [string equal $content_method "xml_import"] } {
	template::forward "revision-upload?content_type=$content_type&parent_id=$parent_id&relation_tag=$relation_tag"
    }

    template::forward "create-2?content_type=$content_type&parent_id=$parent_id&content_method=$content_method&relation_tag=$relation_tag"

}



