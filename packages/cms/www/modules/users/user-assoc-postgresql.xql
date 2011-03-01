<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="user_assoc_root">      
      <querytext>

        declare
          c_rel_cur     record;
        begin 
          for c_rel_cur in 
            select 
              m.rel_id
            from 
              acs_rels r, membership_rels m
            where 
              r.object_id_two = $item_id
            and 
              m.rel_id = r.rel_id
          loop
            PERFORM membership_rel__delete(c_rel_cur.rel_id);
          end loop;

          return null;
        end;
      </querytext>
</fullquery>

 
<fullquery name="user_assoc_root2">      
      <querytext>

        declare
          v_group_id    groups.group_id%TYPE;
          v_user_id     users.user_id%TYPE;
        begin 
          select g.group_id, u.user_id into v_group_id, v_user_id
            from groups g, users u
            where g.group_id = :id and u.user_id = :item_id;

          if not found then 
                return null;
          else 

                return membership_rel__new(
                        null,
                        'membership_rel',
                        :id, 
                        :item_id,
                        'approved',
                        :user_id, 
                        :ip); 
          end if;

          return null;
        end;
      </querytext>
</fullquery>

 
</queryset>
