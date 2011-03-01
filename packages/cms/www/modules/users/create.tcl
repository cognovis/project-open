# Create a subgroup

request create

request set_param parent_id -datatype integer -optional
request set_param mount_point -datatype keyword -optional -value users

form create add_group

element create add_group group_id \
  -label "Group ID" -datatype integer -widget hidden -optional

element create add_group user_id \
  -label "User ID" -datatype integer -widget hidden -value [User::getID] 

element create add_group parent_id \
  -label "Parent ID" -datatype integer -widget hidden -param -optional

element create add_group group_name \
  -label "Name" -datatype text -widget text -html { size 20 }

element create add_group email \
  -label "Email" -datatype text -widget text -optional -html { size 40 }

element create add_group url \
  -label "URL" -datatype text -widget text -optional -html { size 40 }


if { [form is_request add_group] } {
  
    # Get the next folder id
    set group_id [db_string get_group_id ""]

    element set_properties add_group group_id -value $group_id
}

# Insert the folder
if { [form is_valid add_group] } {

  set ip [ns_conn peeraddr]

  template::form get_values add_group group_name parent_id \
                            group_id user_id email url

  db_transaction {

      set group_id [db_exec_plsql new_group "begin :1 := acs_group.new(
    group_id => :group_id, 
    group_name => :group_name, 
    email => :email,
    url => :url,
    creation_user => :user_id, 
    creation_ip => :ip ); end;"]

      if { ![util::is_nil parent_id] } {
          set rel_id [db_exec_plsql new_rel "begin :1 := composition_rel.new(
    object_id_one => :parent_id,
    object_id_two => :group_id,
    creation_user => :user_id, 
    creation_ip => :ip ); end;"]
      }
  }

  # Update the folder and refresh the tree
  refreshCachedFolder $user_id sitemap $parent_id

  template::forward "refresh-tree?id=$parent_id&goto_id=$parent_id&mount_point=$mount_point"
}


