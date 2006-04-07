
-- Being used for "Final Customers" of projects, where
-- the final customer and the invoicing customer are
-- different
insert into im_categories (
        category_id, category, category_type,
        category_gif, category_description)
values (1304, 'Final Customer', 'Intranet Biz Object Role',
        'member', 'Final Customer');


-- Generic association between objects.
-- Dunno what this maybe used for in the future...
insert into im_categories (
        category_id, category, category_type,
        category_gif, category_description)
values (1305, 'Generic Association', 'Intranet Biz Object Role',
        'member', 'Generic Association');


-- Mail Association - Mails assocated with a BizObject
insert into im_categories (
        category_id, category, category_type,
        category_gif, category_description)
values (1306, 'Mail Association', 'Intranet Biz Object Role',
        'member', 'Related Mail');






insert into im_biz_object_urls (object_type, url_type, url) values (
'person','view','/intranet/users/view?user_id=');
insert into im_biz_object_urls (object_type, url_type, url) values (
'person','edit','/intranet/users/new?user_id=');




drop function im_menu__name (integer);

-- Returns the name of the menu
create or replace function im_menu__name (integer) returns varchar as '
DECLARE
        p_menu_id   alias for $1;
        v_name      im_menus.name%TYPE;
BEGIN

    function name (menu_id in integer) return varchar
    is
    begin
        select  name
        into    v_name
        from    im_menus
        where   menu_id = p_menu_id;

        return v_name;
end;' language 'plpgsql';




