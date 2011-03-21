# create-1.tcl
# choose from no content, or file upload
#    then forward to create-2 or revision-upload

request create
request set_param content_type -datatype keyword -value "content_revision"
request set_param mount_point -datatype keyword -value "sitemap"
request set_param parent_id -datatype integer -optional

# Manually set the value since the templating system is still broken in 
# the -value flag
if { [template::util::is_nil parent_id] } {
  set parent_id [cm::modules::${mount_point}::getRootFolderID]
}



# permissions check - need cm_new on the parent item
content::check_access $parent_id cm_new -user_id [User::getID]


set content_type_name [db_string get_content_type ""]

if { [template::util::is_nil content_type_name] } {
    ns_log Notice "ERROR: create-1.tcl - BAD CONTENT_TYPE - $content_type"
    template::forward "../sitemap/index"
}


set page_title "Create a New $content_type_name"

form create choose_captioned_image_content_method
form section choose_captioned_image_content_method "Choose Content Creation Method"

element create choose_captioned_image_content_method parent_id \
	-datatype integer \
	-widget hidden \
	-optional

# ATS doesn't like "-value -100"
set value [element get_value choose_captioned_image_content_method parent_id]
if { [template::util::is_nil value] } {
  upvar 0 "choose_captioned_image_content_method:parent_id" element
  set element(value) $parent_id
}

element create choose_captioned_image_content_method content_type \
	-datatype keyword \
	-widget hidden \
	-value $content_type

element create choose_captioned_image_content_method content_method \
	-datatype keyword \
	-widget radio \
	-label "Method" \
	-options { {{No Content} no_content} {{File Upload} file_upload} } \
	-values [list "no_content"]

if { [form is_valid choose_captioned_image_content_method] } {

    form get_values choose_captioned_image_content_method \
	    content_type parent_id content_method

    template::forward \
	    "create-2?content_type=$content_type&parent_id=$parent_id&content_method=$content_method"

}
