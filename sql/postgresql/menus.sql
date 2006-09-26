

-- Select a specific menu. Label is used as a fixed reference
-- See the Menu maintenance screens for the name of the parent 
-- menu.

select menu_id 
from im_menus 
where label='finance'
;


-- Select all menus below a Parent with read permissions of the
-- current user

        select  m.*
        from    im_menus m
        where   parent_menu_id = :parent_menu_id
                and enabled_p = 't'
                and im_object_permission_p(m.menu_id, :user_id, 'read') = 't'
        order by sort_order
;


