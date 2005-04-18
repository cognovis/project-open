request create 
request set_param id -datatype keyword
request set_param mount_point -datatype keyword -optional -value users
request set_param parent_id -datatype keyword -optional

set user_id [User::getID]
set ip [ns_conn peeraddr]

db_transaction {

    if { [template::util::is_nil id] } {
        set code {
            if { [catch { 
                db_exec_plsql user_assoc_root "
        declare
          v_id membership_rels.rel_id%TYPE;
          cursor c_rel_cur is
            select 
              m.rel_id
            from 
              acs_rels r, membership_rels m
            where 
              r.object_id_two=$item_id
            and 
              m.rel_id = r.rel_id;
        begin 
          open c_rel_cur;
          loop
            fetch c_rel_cur into v_id;
            exit when c_rel_cur%NOTFOUND;
            membership_rel.del(v_id);
          end loop;
        end;"
            } errmsg] } {
            }
        }             
        
    } else {
        set code {
            if { [catch { 
                set rel_id [db_exec_plsql user_assoc_root2 "
        declare
          v_group_id groups.group_id%TYPE;
          v_user_id users.user_id%TYPE;
        begin 
          select g.group_id, u.user_id into v_group_id, v_user_id
            from groups g, users u
            where g.group_id = :id and u.user_id = :item_id;

          :1 := membership_rel.new(
          object_id_one => :id, object_id_two => :item_id,
          creation_user => :user_id, creation_ip => :ip); 

          exception when no_data_found then null;
        end;"]
            } errmsg] } {
            }
        }   
    }

    set clip [clipboard::parse_cookie]

    clipboard::map_code $clip $mount_point $code
}

clipboard::free $clip

# Specify a null id so that the entire branch will be refreshed
template::forward "refresh-tree?goto_id=$id&id=$id&mount_point=$mount_point"


 
  
  
  
