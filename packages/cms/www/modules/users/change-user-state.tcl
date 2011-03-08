# Change the user's membership state

request create
request set_param rel_id -datatype keyword
request set_param group_id -datatype keyword
request set_param new_state -datatype keyword
request set_param parent_id -datatype keyword -optional
request set_param mount_point -datatype keyword -optional -value users

db_transaction {
    db_dml change_member_state "
 update membership_rels set
   member_state=:new_state 
 where 
   rel_id=:rel_id" 
}

template::forward "index?id=$group_id&parent_id=$parent_id&mount_point=$mount_point"
