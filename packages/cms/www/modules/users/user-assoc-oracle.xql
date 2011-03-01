<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="user_assoc_root">      
      <querytext>
      
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
        end;
      </querytext>
</fullquery>

 
<fullquery name="user_assoc_root2">      
      <querytext>
      
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
        end;
      </querytext>
</fullquery>

 
</queryset>
