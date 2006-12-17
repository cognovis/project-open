-- intranet-dw-light/upgrade-3.2.5.0.0-3.2.6.0.0.sql


create or replace function inline_1 ()
returns integer as '
declare
      v_menu                  integer;
      v_users_admin_menu      integer;

      v_employees             integer;
      v_accounting            integer;
      v_senman                integer;
      v_customers             integer;
      v_freelancers           integer;
      v_proman                integer;
      v_admins                integer;
      v_reg_users             integer;
begin
    select group_id into v_admins from groups where group_name = ''P/O Admins'';
    select group_id into v_senman from groups where group_name = ''Senior Managers'';
    select group_id into v_proman from groups where group_name = ''Project Managers'';
    select group_id into v_accounting from groups where group_name = ''Accounting'';
    select group_id into v_employees from groups where group_name = ''Employees'';
    select group_id into v_customers from groups where group_name = ''Customers'';
    select group_id into v_freelancers from groups where group_name = ''Freelancers'';
    select group_id into v_reg_users from groups where group_name = ''Registered Users'';

    select menu_id
    into v_users_admin_menu
    from im_menus
    where label=''users_admin'';

    v_menu := im_menu__new (
        null,                   -- p_menu_id
        ''acs_object'',         -- object_type
        now(),                  -- creation_date
        null,                   -- creation_user
        null,                   -- creation_ip
        null,                   -- context_id
        ''intranet-core'',      -- package_name
        ''users_admin_csv'',    -- label
        ''Export Users Cube'',  -- name
        ''/intranet-dw-light/users.csv'',  -- url
        10,                     -- sort_order
        v_users_admin_menu,     -- parent_menu_id
        null                    -- p_visible_tcl
    );

    return 0;
end;' language 'plpgsql';
select inline_1 ();
drop function inline_1 ();





