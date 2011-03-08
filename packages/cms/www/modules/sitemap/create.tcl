# Create a new folder under the current folder

request create -params {
  parent_id -datatype integer -optional
  mount_point -datatype keyword
}

if { [util::is_nil parent_id] } {
  set create_parent_id [cm::modules::${mount_point}::getRootFolderID]
} else {
  set create_parent_id $parent_id
} 


# permissions check - user must have cm_new on parent
content::check_access $create_parent_id cm_new -user_id [User::getID] 

# Get the path
set path [db_string get_path ""]

# Create the form

form create add_folder

element create add_folder parent_id \
  -label "Parent ID" -datatype keyword -widget hidden -param -optional

element create add_folder mount_point \
  -label "Mount Point" -datatype keyword -widget hidden -param -optional

if { [string equal $path ""] } {
    set path "/"
}

element create add_folder path \
  -label "In" -datatype text -widget inform -value "<tt>$path</tt>"

element create add_folder name \
  -label "Name" -datatype keyword -widget text -html { size 20 } \
  -validate { { expr ![string match $value "/"] } 
              { Folder name cannot contain slashes }}

element create add_folder label \
  -label "Label" -widget text -datatype text \
  -html { size 30 } -optional

element create add_folder description \
  -label "Description" -widget textarea -datatype text \
  -html { rows 5 cols 40 wrap physical } -optional

#set parent_id [element get_value add_folder parent_id]
#set mount_point [element get_value add_folder mount_point]


# Insert the folder
if { [form is_valid add_folder] } {
    form get_values add_folder \
	    name label description parent_id mount_point

    set user_id [User::getID]
    set ip [ns_conn peeraddr]
  
    db_transaction {

        set folder_id [db_exec_plsql new_folder "
    begin 
    :1 := content_folder.new(
        name          => :name, 
        label         => :label, 
        description   => :description,
        parent_id     => :create_parent_id, 
        creation_user => :user_id, 
        creation_ip   => :ip ); 
    end;"]

        if { [string equal $mount_point "templates"] } {

            db_exec_plsql register_content_type "
	  begin
	  content_folder.register_content_type(
	      folder_id        => :folder_id,
	      content_type     => 'content_template',
	      include_subtypes => 'f' 
	  );
	  end;"
        }

    }

    # Flush the paginator cache
    cms_folder::flush $mount_point $parent_id

    # Update the folder and refresh the tree
    refreshCachedFolder $user_id sitemap $parent_id

    forward "refresh-tree?id=$parent_id&goto_id=$parent_id&mount_point=$mount_point"
}
