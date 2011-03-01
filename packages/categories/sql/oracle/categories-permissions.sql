--
-- The Categories Package
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2003-04-16
--

begin
    -- create the privileges
    acs_privilege.create_privilege('category_tree_write');
    acs_privilege.create_privilege('category_tree_read');
    acs_privilege.create_privilege('category_tree_grant_permissions');

    acs_privilege.create_privilege('category_admin', 'Categories Administrator');
    acs_privilege.add_child('admin','category_admin');      
    acs_privilege.add_child('category_admin','category_tree_read');
    acs_privilege.add_child('category_admin','category_tree_write');
    acs_privilege.add_child('category_admin','category_tree_grant_permissions');
end;
/
show errors;
commit;
