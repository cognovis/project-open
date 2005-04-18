# Create a new item and an initial revision for a content item (generic)

form create create_item

element create create_item item_id -datatype integer -widget hidden
element create create_item revision_id -datatype integer -widget hidden
element create create_item context_id -datatype integer -widget hidden \
  -param -optional

element create create_item name -datatype keyword -widget text
element create create_item title -datatype text -widget text
element create create_item description -datatype text -widget textarea \
    -html { cols 60 rows 5 } -label "Description"

element create create_item publish_date -datatype date -widget date

set mime_types [db_list_of_lists get_mime_types ""]

element create create_item mime_type -datatype text -widget select \
                                     -options $mime_types

element create create_item text -datatype text -widget textarea \
    -html { cols 60 rows 10 }

if { [form is_request create_item] } {

    set item_id [db_string get_item_id ""]
    element set_properties create_item item_id -value $item_id

    set revision_id [db_string get_revision_id ""]
    element set_properties create_item revision_id -value $revision_id
}

if { [form is_valid create_item] } {


  # set the date value from the form
  form get_values create_item name context_id item_id title description \
                  publish_date mime_type text revision_id

  set publish_date [util::date::get_property sql_date $publish_date]

  set retval [db_exec_plsql new_content_item "begin 
    :1 := content_item.new(:name, :context_id, :item_id, sysdate, NULL,
                           '[ns_conn peeraddr]', 'content_item'); 
  end;"]

  set retval [db_exec_plsql new_revision "begin 
    :1 := content_revision.new(:title, :description, $publish_date, 
                               :mime_type, NULL, :text, 'content_revision', 
                               :item_id, :revision_id);
  end;"]

  template::forward item?item_id=$item_id
}

