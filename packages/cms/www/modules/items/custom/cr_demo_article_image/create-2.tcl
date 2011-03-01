# custom creation form for content_type = cr_demo_article_image



request create
request set_param parent_id      -datatype integer
request set_param content_type   -datatype keyword
request set_param content_method -datatype keyword


# permissions check - need cm_new on parent_id to create new captioned image
content::check_access $parent_id cm_new -user_id [User::getID]



form create captioned_image -html { enctype "multipart/form-data" } -elements {
    parent_id      -datatype integer -widget hidden -param
    content_type   -datatype keyword -widget hidden -param
    content_method -datatype keyword -widget hidden -param
    item_id        -datatype integer -widget hidden
    name           -datatype keyword -widget hidden
}

content::add_attribute_element captioned_image content_revision title
content::add_attribute_element captioned_image content_revision description

content::add_attribute_element captioned_image image width
element set_properties captioned_image width -help_text "(optional)"

content::add_attribute_element captioned_image image height
element set_properties captioned_image height -help_text "(optional)"

# regardless of method, we are going to have a caption for this item
content::add_attribute_element captioned_image cr_demo_article_image caption



if { [string equal $content_method "file_upload"] } {
    # if the method is file upload, provide a form element to specify the file
    element create captioned_image upload \
	    -datatype text \
	    -widget file \
	    -label "Upload Image"

    # also keep the caption form element visible and) add some help text
    element set_properties captioned_image caption -help_text "(optional)"
} else {
    # if "No content" then provide a default value for the caption
    element set_properties captioned_image caption \
	    -widget hidden \
	    -value "Enter caption here"
}




if { [form is_request captioned_image] } {
    set item_id [content::get_object_id]
    element set_value captioned_image item_id $item_id
    element set_value captioned_image name "image_$item_id"
}




if { [form is_valid captioned_image] } {
    form get_values captioned_image \
	    parent_id content_type item_id name title description caption

    # default
    set mime_type ""

    if { [string equal $content_method "file_upload"] } {

	form get_values captioned_image upload
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
    }

    # use user input width and height
    if { [element exists captioned_image width] } {
	set width [element get_value captioned_image width]
    }
    if { [element exists captioned_image height] } {
	set height [element get_value captioned_image height]
    }

    if { [string equal $content_method "file_upload"] } {
	# otherwise use detected width and height
	if { [template::util::is_nil width] } {
	    set width  [lindex $image_size 0]
	}
	if { [template::util::is_nil height] } {
	    set height [lindex $image_size 1]
	}
    }

    # some auditing info
    set user_id [User::getID]
    set ip_address [ns_conn peeraddr]

    db_transaction {
        
        # create a new cr_demo_article_image item

        if { [catch {db_exec_plsql new_content"
      begin 
      :1 := content_item.new(
          name          => :name, 
          item_id       => :item_id,
          parent_id     => :parent_id, 
          content_type  => :content_type,
          creation_user => :user_id,
          creation_ip   => :ip_address
      ); 
      end;" } item_id] } {
            ns_log notice "custom/cr_demo_article_image/create-1.tcl caught error 
	  - $errmsg"

            # check for double click
            set clicks [db_string get_clicks ""]

            db_abort_transaction

            if { $clicks > 0 } {
                # double click error - do nothing, forward to view the item
                template::forward \
		    "../../index?item_id=$item_id"
            } else {
                template::request::error new_item_error \
		    "custom/cr_demo_article_image/create-1.tcl - 
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
      end;
    "]

        # insert the extended attributes
        db_dml insert_image "
      insert into images (
        image_id, width, height
      ) values (
        :revision_id, :width, :height
      )"

        db_dml insert_art_image "
      insert into cr_demo_article_images (
        article_image_id, caption
      ) values (
        :revision_id, :caption
      )"

        if { [string equal $content_method "file_upload"] } {
            # upload the image
            db_dml update_content "
          update cr_revisions
            set content = empty_blob()
            where revision_id = $revision_id
            returning content into :1" -blob_files $tmp_filename
        }
    }


    # flush the paginator cache
    cms_folder::flush sitemap $parent_id

    template::forward "../../index?item_id=$item_id"
}
