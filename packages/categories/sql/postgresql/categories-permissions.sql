--
-- The Categories Package
--
-- @author Timo Hentschel (timo@timohentschel.de)
-- @creation-date 2003-04-16
--

begin;
    -- create the privileges
    select acs_privilege__create_privilege('category_tree_write', null, null);
    select acs_privilege__create_privilege('category_tree_read', null, null);
    select acs_privilege__create_privilege('category_tree_grant_permissions', null, null);

    select acs_privilege__create_privilege('category_admin','Categories Administrator','Categories Administrators');
    select acs_privilege__add_child('admin','category_admin');      
    select acs_privilege__add_child('category_admin','category_tree_read');
    select acs_privilege__add_child('category_admin','category_tree_write');
    select acs_privilege__add_child('category_admin','category_tree_grant_permissions');
end;
