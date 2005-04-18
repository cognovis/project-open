# List the contents of a folder under in the template repository

# Either a path or a folder ID may be passed to the page.

request create -params {
  id -datatype integer
  path -datatype text
}

set package_url [ad_conn package_url]
set clipboardfloats_p [clipboard::floats_p]

# Tree hack
if { $id == [cm::modules::templates::getRootFolderID] } {
  set refresh_id ""
} else {
  set refresh_id $id
}

if { ! [string equal $path {}] } {

    set id [db_string get_id ""]

    if { [string equal $id {}] } {

        set msg "The requested folder <tt>$path</tt> does not exist."
        request error invalid_path $msg
    }
} else {

  if { [string equal $id {}] } {
      set id [db_string get_root_folder_id ""]
  }

  set path [db_string get_path ""]
}

# query for the content type and redirect if a folder

set type [db_string get_type ""]

if { [string equal $type content_template] } {
  template::forward properties?id=$id
}

# Query for the parent

if { ! [string equal $path /] } {
    db_0or1row get_parent "" -column_array parent
}

# Query folders first

db_multirow folders get_folders ""

# items in the folder

db_multirow items get_items ""

# set a flag indicating whether the folder is empty

set is_empty [expr ! ( ${items:rowcount} || ${folders:rowcount} )]
