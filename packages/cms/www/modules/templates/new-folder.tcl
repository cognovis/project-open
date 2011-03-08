request create -params {
  parent_id -datatype integer
}

set path [db_string get_path ""]

form create new_folder -elements "
  return_url -datatype url -widget hidden
  folder_id -datatype integer -widget hidden
  parent_id -datatype integer -widget hidden
  name -datatype filename -html { size 40 } -label {Folder Name}
  label -datatype text -html { size 40 } -optional
  description -datatype text -widget textarea -optional \
    -html { rows 4 cols 40 }
"

if { [form is_request new_folder] } {

  element set_value new_folder folder_id [content::get_object_id]
  element set_value new_folder parent_id $parent_id

  set return_url [ns_set iget [ns_conn headers] Referer]
  element set_properties new_folder return_url -value $return_url

} else {

  set return_url [element get_value new_folder return_url]
}

if { [string equal [ns_queryget action] "Cancel"] } {
  template::forward $return_url
}

if { [form is_valid new_folder] } {

  form get_values new_folder parent_id name folder_id label description

  set creation_ip [ns_conn peeraddr]
  set creation_user [User::getID]

  db_transaction {

      set folder_id [db_exec_plsql new_folder "begin :1 := content_folder.new(
         folder_id => :folder_id,
         name => :name,
         label => :label,
         description => :description,
         parent_id => :parent_id,
         creation_ip   => :creation_ip,
         creation_user => :creation_user
  ); end;"]

      content::add_basic_revision $folder_id "" "Template" \
          -text "<html></html>"
  }

  template::forward $return_url
}
