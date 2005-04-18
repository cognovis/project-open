# custom creation form for content_type = image

request create
request set_param parent_id    -datatype integer
request set_param content_type -datatype keyword


# permissions check - need cm_new on parent_id to create new image
content::check_access $parent_id cm_new -user_id [User::getID]



form create image -html { enctype "multipart/form-data" } -elements {
    parent_id    -datatype integer -widget hidden -param
    content_type -datatype keyword -widget hidden -param
    item_id      -datatype integer -widget hidden
    name         -datatype keyword -widget hidden
}

	
content::add_attribute_element image content_revision title
content::add_attribute_element image content_revision description

content::add_attribute_element image image width
element set_properties image width -help_text "(optional)"

content::add_attribute_element image image height
element set_properties image height -help_text "(optional)"

element create image upload \
	-datatype text \
	-widget file \
	-label "Upload Image"

# Add the relation tag element
content::add_child_relation_element image -section

if { [form is_request image] } {

    set item_id [content::get_object_id]

    element set_value image item_id $item_id
    element set_value image name    "image_$item_id"
}




if { [form is_valid image] } {
    form get_values image \
	    parent_id content_type item_id name title description upload

    if { [element exists image relation_tag] } {
      set relation_tag [element get_value image relation_tag]
    } else {
      set relation_tag ""
    }

    set tmp_filename [ns_queryget upload.tmpfile]

    # MIME type validation
    set mime_type [ns_guesstype $upload]

    if { ![regexp {image/(.*)} $mime_type match image_type] } {
	template::request::error invalid_image_mime_type \
		"The specified MIME is not valid for an image - $mime_type."
	return
    }


    # image width and height validation
    set size_command "ns_${image_type}size"
    if { [catch {set image_size [$size_command $tmp_filename] } errmsg] } {
	template::request::error invalid_image_size \
		"The file is not a valid image file - $tmp_filename"
	return
    }

    # use user input width and height
    if { [element exists image width] } {
	set width [element get_value image width]
    }
    if { [element exists image height] } {
	set height [element get_value image height]
    }

    # otherwise use detected width and height
    if { [template::util::is_nil width] } {
	set width  [lindex $image_size 0]
    }
    if { [template::util::is_nil height] } {
	set height [lindex $image_size 1]
    }

    # some auditing info
    set user_id [User::getID]
    set ip_address [ns_conn peeraddr]




    db_transaction {
        
        # create a new image item

        if { [catch {db_exec_plsql "
      begin 
      :item_id := content_item.new(
          name          => :name, 
          item_id       => :item_id,
          parent_id     => :parent_id, 
          content_type  => :content_type,
          creation_user => :user_id,
          creation_ip   => :ip_address,
          relation_tag  => :relation_tag
      ); 
      end;"} item_id] } {
            ns_log notice "custom/image/create-1.tcl caught error - $errmsg"

            # check for double click
            set clicks [db_string get_clicks ""]

            db_abort_transaction

            if { $clicks > 0 } {
                # double click error - do nothing, forward to view the item
                template::forward \
		    "../../index?item_id=$item_id"
            } else {
                template::request::error new_item_error \
		    "custom/image/create-1.tcl - 
	               while creating new $content_type item - $errmsg"
                return
            }
        }

        # create the revision
        set revision_id [db_exec_plsql new_revision "
      begin
      :1 := content_revision.new (
        item_id       => :item_id,
        title         => :title,
        description   => :description,
        mime_type     => :mime_type,
        creation_user => :user_id,
        creation_ip   => :ip_address
      );
      end;"]

        # insert the extended attributes
        db_dml insert_images "
      insert into images (
        image_id, width, height
      ) values (
        :revision_id, :width, :height
      )"

        # upload the image
        db_dml insert_revisions "
      update cr_revisions
        set content = empty_blob()
        where revision_id = $revision_id
        returning content into :1" -blob_files $tmp_filename

    }

    # flush the paginator cache
    cms_folder::flush sitemap $parent_id

    template::forward "../../index?item_id=$item_id"
}
