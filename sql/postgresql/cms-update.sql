
-- Modify permissions to include the cm_relate permission
create or replace function inline_0 ()
returns integer as '
declare
  v_exists integer;
begin
  select count(*) into v_exists from acs_privileges 
    where privilege = ''cm_admin'';

  if v_exists > 0 then
    select count(*) into v_exists from acs_privileges 
      where privilege = ''cm_relate'';

    if v_exists < 1 then
      update acs_privilege_hierarchy 
	set privilege = ''cm_relate''
      where privilege = ''cm_admin'' 
	and child_privilege = ''cm_write'';
    end if;
  end if;

  return 0;
end;' language 'plpgsql';

select inline_0 ();

drop function inline_0 ();


-- show errors

-- This parent_id column was not included in the cr_keywords table
-- for RC 0.  Ensure this column is there.

create or replace function inline_1 ()
returns integer as '
begin

  if not column_exists(''cr_keywords'', ''parent_id'') then

    raise notice ''Adding PARENT_ID column to CR_KEYWORDS and updating the parent id from the context id'';

    execute ''alter table cr_keywords add 
       parent_id      integer 
                      constraint cr_keywords_hier
                      references cr_keywords'';

    execute ''update cr_keywords set parent_id = (
                         select context_id from acs_objects 
                         where object_id = keyword_id)'';

  end if;

  return 0;
end;' language 'plpgsql';

select inline_1 ();

drop function inline_1 ();


-- show errors

-- Drop the broken trigger, if any
create or replace function inline_2 ()
returns integer as '
begin
  -- FIXME: DCW - can''t locate where this trigger is created.  Need a table
  -- name in order to drop it in pg.

  -- execute ''drop trigger cr_item_permission_tr'';

  return 0;
end;' language 'plpgsql';

select inline_2 ();

drop function inline_2 ();


-- show errors

select content_type__register_mime_type ('content_template', 'text/html');
select content_type__register_mime_type ('content_template', 'text/plain');
