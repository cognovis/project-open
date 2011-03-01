# Edit a subgroup

request create

request set_param id -datatype integer -optional
request set_param parent_id -datatype integer -optional
request set_param mount_point -datatype keyword -optional -value users

form create edit_group

element create edit_group group_id \
  -label "Group ID" -datatype integer -widget hidden -value $id

element create edit_group user_id \
  -label "User ID" -datatype integer -widget hidden -value [User::getID] 

element create edit_group mount_point \
  -label "Mount Point" -datatype keyword -widget hidden -param -optional

element create edit_group parent_id \
  -label "Parent ID" -datatype keyword -widget hidden -param -optional

element create edit_group group_name \
  -label "Name" -datatype text -widget text -html { size 20 }

element create edit_group email \
  -label "Email" -datatype text -widget text -optional -html { size 40 }

element create edit_group url \
  -label "URL" -datatype text -widget text -optional -html { size 40 }

if { [form is_request edit_group] } {

    db_1row get_group_info "" -column_array info

  element set_properties edit_group group_name -value $info(group_name)
  element set_properties edit_group email -value $info(email)
  element set_properties edit_group url -value $info(url)
}

if { [form is_valid edit_group] } {
 
  template::form get_values edit_group group_id user_id group_name \
                            email url mount_point

  db_transaction {
      db_dml edit_group_1 "
    update groups 
      set group_name = :group_name
      where group_id = :group_id"
      db_dml edit_group_2 "
    update parties
      set email = :email, url = :url
      where party_id = :group_id"
  }

  refreshCachedFolder $user_id $mount_point $parent_id

  template::forward "refresh-tree?id=$parent_id&goto_id=$group_id&mount_point=$mount_point"
}


  



