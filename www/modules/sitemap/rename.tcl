# Change name, label and description of folder.

request create
request set_param item_id -datatype integer
request set_param mount_point -datatype keyword -value sitemap


# permissions check - renaming a folder requires cm_write on the folder
content::check_access $item_id cm_write -user_id [User::getID] 


# Create then form
form create rename_folder

element create rename_folder item_id \
  -datatype integer -widget hidden -param

element create rename_folder parent_id \
  -datatype integer -widget hidden -optional -param

element create rename_folder mount_point \
  -datatype keyword -widget hidden -value $mount_point

element create rename_folder name \
  -label "Name" -datatype keyword -widget text -html { size 20 } \
  -validate { { expr ![string match $value "/"] } 
              { Folder name cannot contain slashes }}

element create rename_folder label \
  -label "Label" -widget text -datatype text \
  -html { size 30 } -optional

element create rename_folder description \
  -label "Description" -widget textarea -datatype text \
  -html { rows 5 cols 40 wrap physical } -optional


if { [form is_request rename_folder] } {
  
  set item_id [element get_value rename_folder item_id]

  # Get existing folder parameters
  db_1row get_info "" -column_array info

  element set_properties rename_folder name -value $info(name)
  element set_properties rename_folder label -value $info(label)
  element set_properties rename_folder description -value $info(description)
}






# Rename
if { [form is_valid rename_folder] } {

  form get_values rename_folder \
	  item_id name label description parent_id mount_point

  db_transaction {

      db_exec_plsql rename_folder "
    begin 
    content_folder.edit_name (
        folder_id   => :item_id, 
        name        => :name, 
        label       => :label, 
        description => :description
    ); 
    end;"
  }

  # flush paginator cache for this folder
  cms_folder::flush $mount_point $parent_id

  template::forward "refresh-tree?id=$parent_id&goto_id=$item_id"
}

