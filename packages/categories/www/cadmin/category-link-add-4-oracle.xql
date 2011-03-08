<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="check_link_forward_permissions">
      <querytext>
      
    select c.category_id as link_category_id
    from categories c
    where c.category_id in ([join $link_category_id ,])
    and acs_permission__permission_p(c.tree_id,:user_id,'category_tree_write') = 't'
    and c.category_id <> :category_id
    and not exists (select 1
                    from category_links l
                    where l.from_category_id = :category_id
                    and l.to_category_id = c.category_id)

      </querytext>
</fullquery>

 
<fullquery name="check_link_backward_permissions">
      <querytext>
      
    select c.category_id as link_category_id
    from categories c
    where c.category_id in ([join $link_category_id ,])
    and acs_permission__permission_p(c.tree_id,:user_id,'category_tree_write') = 't'
    and c.category_id <> :category_id
    and not exists (select 1
                    from category_links l
                    where l.from_category_id = c.category_id
                    and l.to_category_id = :category_id)

      </querytext>
</fullquery>

 
</queryset>
