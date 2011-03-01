# /create-2.tcl
# Get the folder where the item is being created

# Parameters:
#
#  parent_id      - create the item under this parent (required)
#  content_type   - use this content type (required)
#  content_method - no_content file_upload text_entry
#  return_url     - the url where the browser will go after the item is created
#                   (default index)
#  is_wizard      - use the wizard style form template?  if wizard exists, 
#                   setting this to 'f' won't override the wizard formatting

request create
request set_param parent_id -datatype integer
request set_param content_type -datatype keyword
request set_param content_method -datatype keyword -value "no_content"
request set_param relation_tag -datatype text -optional

# optional
request set_param return_url -datatype text -value "index"
request set_param page_title -datatype text -optional
request set_param is_wizard -datatype keyword -value f

# permissions check - need cm_new on the parent item
content::check_access $parent_id cm_new -user_id [User::getID]

db_0or1row get_item "" -column_array new_item

# validate content_type and parent_id
if { [template::util::is_nil new_item] } {
    template::request::error create_item_form_generation_error \
	    "Bad parent_id = $parent_id or bad content_type = $content_type"
}
template::util::array_to_vars new_item

# set default page title
if { [template::util::is_nil page_title] } {
  set page_title "Create a $content_type_name"
}


# Create a form for the basic item, no revision info
form create create_item -html { enctype "multipart/form-data" }

element create create_item item_path \
	 -datatype text \
  	 -widget inform \
	 -label "Folder" \
	 -value $item_path

element create create_item content_type_name \
	-datatype text \
	-widget inform \
	-label "Content Type" \
	-value $content_type_name 

element create create_item return_url \
        -datatype text \
	-widget hidden \
        -optional \
	-value $return_url

element create create_item relation_tag \
        -datatype text \
	-widget hidden \
        -optional \
	-param

# auto-generated form
content::new_item_form -form_name create_item \
	-parent_id $parent_id \
	-content_type $content_type \
	-content_method $content_method

# added to support content storage selection (OpenACS - DanW)
element create create_item storage_type \
	-datatype keyword \
	-widget radio \
	-label "Content Storage Type" \
        -options { {{Lob Storage} lob } {{File Storage} file} {{Text Storage} text}} \
	-values [list "text"]

if { [wizard exists] } {
  set is_wizard t
  wizard submit create_item
}


# create a new content item
if { [form is_valid create_item] } {

    # check for duplicate name within same folder or parent item.
    if { ![content::validate_name create_item] } {
	set name [template::element get_value create_item name]
	template::element::set_error create_item name \
		"The name \"$name\" is already in use by an existing item<br> 
	         in the same folder or parent item."
	return
    }

    form get_values create_item return_url item_id storage_type
    
    set item_id [content::new_item create_item $storage_type]

    # do wizard forward or forward to return_url
    if { ![wizard exists] } { 
	template::forward \
		[content::assemble_url $return_url "item_id=$item_id"]
    } else {
	template::wizard forward
    }
}
