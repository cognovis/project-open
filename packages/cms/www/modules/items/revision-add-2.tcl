# Add a revision of the item

request create
request set_param item_id -datatype integer
request set_param content_method -datatype keyword -value no_content

# check permissions - user must have cm_write on the item
content::check_access $item_id cm_write -user_id [User::getID]

# get content_type and name of item
db_0or1row get_one_item ""

# validate item_id
if { [template::util::is_nil content_type] } {
  template::request::error add_revision "Error - invalid item_id - $item_id"
}

set page_title "Add a Revision to $name"


# check for custom revision-add-1 form
if { [file exists [ns_url2file \
  "custom/$content_type/revision-add-1.tcl"]] } {
  template::forward "custom/$content_type/revision-add-1?item_id=$item_id&content_method=$content_method"
}

form create add_revision -html { enctype "multipart/form-data" }

# autogenerate the revision form
content::add_revision_form \
	-form_name add_revision \
	-content_method $content_method \
	-content_type $content_type \
	-item_id $item_id

if { [form is_valid add_revision] } {
    form get_values add_revision item_id

    # autoprocess the revision form
    content::add_revision add_revision

    template::forward "index?item_id=$item_id"
}
