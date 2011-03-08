# Add a revision of the item - keep the same content as the latest revision

request create
request set_param item_id -datatype integer

# check permissions - user must have cm_write on the item
content::check_access $item_id cm_write -user_id [User::getID]

db_0or1row get_item ""

# flush the sitemap folder listing cache in anticipation 
# of the new item
cms_folder::flush sitemap $item_id

# validate item_id
#  if one_item doesn't exist, then this item may have no latest revision
#  so redirect to the add_revision page with content_method = no_content
if { [template::util::is_nil content_type] } {
    template::forward "revision-add-2?item_id=$item_id&content_method=no_content"
}


# check for custom form
if { [file exists [ns_url2file \
	"custom/$content_type/attributes-edit.tcl"]] } {
    template::forward \
	    "custom/$content_type/attributes-edit?item_id=$item_id"
}

set page_title "Edit Attributes for $name - $title"

# Create the form

form create add_revision -html { enctype "multipart/form-data" } -elements {
    item_id         -datatype integer -widget hidden
    latest_revision -datatype integer -widget hidden
    revision_id     -datatype integer -widget hidden
    content_method  -datatype keyword -widget hidden -value "no_content"
}

# autogenerate the revision form
set attributes_list [content::add_attribute_elements add_revision \
	$content_type $latest_revision]

# populate necessary form elements
if { [form is_request add_revision] } {
    element set_value add_revision item_id $item_id
    element set_value add_revision latest_revision $latest_revision
    element set_value add_revision revision_id [content::get_object_id]
}


# Process the form
if { [form is_valid add_revision] } {
    form get_values add_revision item_id latest_revision revision_id

    # autoprocess the revision form
    #  requires item_id and revision_id to be set in the form
    content::add_revision add_revision

    # copy the content (including mime_type)
    content::copy_content $latest_revision $revision_id

    template::forward "index?item_id=$item_id"
}
