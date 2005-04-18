# custom creation form for content_type = image

request create
request set_param revision_id -datatype integer


set item_id [db_string get_item_id ""]

# permissions check - need cm_new on parent_id to create new image
content::check_access $item_id cm_write -user_id [User::getID]



form create image -html { enctype "multipart/form-data" } -elements {
    revision_id  -datatype integer -widget hidden -param
    item_id      -datatype integer -widget hidden
}

element set_value image item_id $item_id
	
element create image upload \
	-datatype text \
	-widget file \
	-label "Upload Image"




if { [form is_valid image] } {
    form get_values image \
	    revision_id item_id upload
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
    set width  [lindex $image_size 0]
    set height [lindex $image_size 1]


    db_transaction {
        
        # insert the extended attributes
        db_dml update_images "
      update images
        set width = :width,
        height = :height
        where image_id = :revision_id"

        # upload the image
        db_dml update_revisions "
      update cr_revisions
        set content = empty_blob()
        where revision_id = $revision_id
        returning content into :1" -blob_files $tmp_filename

    }


    template::forward "../../index?item_id=$item_id"
}
