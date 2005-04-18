# revision-add-1.tcl
# custom form for content_type = image

request create
request set_param item_id -datatype integer


# permissions check - need cm_write on item_id to add a revision
content::check_access $item_id cm_write -user_id [User::getID]




form create image -html { enctype "multipart/form-data" } -elements {
    item_id      -datatype integer -widget hidden -param
}

db_1row get_item_info ""

content::add_attribute_elements image image $latest_revision

element set_properties image mime_type -widget hidden
element set_properties image width -help_text "(optional)"
element set_properties image height -help_text "(optional)"


element create image upload \
	-datatype text \
	-widget file \
	-label "Upload Image"



if { [form is_valid image] } {

    form get_values image item_id title description upload
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

    # if the width or height exist in the form, use it
    if { [element exists image width] } {
	set width [element get_value image width]
    }
    if { [element exists image height] } {
	set height [element get_value image height]
    }

    # otherwise use the auto generated image dimensions
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
        db_dml insert_images "
      insert into images (
        image_id, width, height
      ) values (
        :revision_id, :width, :height
      )"

        # upload the image
        db_dml update_revisions "
      update cr_revisions
        set content = empty_blob()
        where revision_id = $revision_id
        returning content into :1" -blob_files $tmp_filename



    }

    template::forward "../../index?item_id=$item_id"

}
