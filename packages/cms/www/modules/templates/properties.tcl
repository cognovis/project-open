request create -params {
  id -datatype integer
  path -datatype text
  tab -datatype keyword -value revisions
}

if { ! [string equal $path {}] } {

    set id [db_string get_id ""]

    if { [string equal $id {}] } {

        set msg "The requested folder <tt>$path</tt> does not exist."
        request error invalid_path $msg
    }

} else {

  if { [string equal $id {}] } {
      set id [db_string get_root_id ""]
  }

  set path [db_string get_path ""]
}

# query for the content type and redirect if a folder

set type [db_string get_type ""]

if { [string equal $type content_folder] } {
  template::forward index?id=$id
}

multirow create tabs label name
multirow append tabs General general
multirow append tabs History revisions
multirow append tabs {Data Sources} datasources
multirow append tabs Assets assets
multirow append tabs {Content Types} types
multirow append tabs {Content Items} items

set tab_count [expr ${tabs:rowcount} * 2]
