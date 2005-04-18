
-- Modify permissions to include the cm_relate permission
declare
  v_exists integer;
begin
  select count(*) into v_exists from acs_privileges 
    where privilege = 'cm_admin';

  if v_exists > 0 then
    select count(*) into v_exists from acs_privileges 
      where privilege = 'cm_relate';

    if v_exists < 1 then
      acs_privilege.create_privilege('cm_relate', 'Relate Items', 'Relate Items'); 
      acs_privilege.add_child('cm_admin', 'cm_relate');
      update acs_privilege_hierarchy 
	set privilege = 'cm_relate'
      where privilege = 'cm_admin' 
	and child_privilege = 'cm_write';
    end if;
  end if;
end;
/
show errors

-- This parent_id column was not included in the cr_keywords table
-- for RC 0.  Ensure this column is there.

begin

  if not column_exists('cr_keywords', 'parent_id') then

    dbms_output.put_line('Adding PARENT_ID column to CR_KEYWORDS' || 
      ' and updating the parent id from the context id');

    execute immediate 'alter table cr_keywords add 
       parent_id      integer 
                      constraint cr_keywords_hier
                      references cr_keywords';

    execute immediate 'update cr_keywords set parent_id = (
                         select context_id from acs_objects 
                         where object_id = keyword_id)';

  end if;

end;
/
show errors

-- Drop the broken trigger, if any
begin
  execute immediate 'drop trigger cr_item_permission_tr';
exception when others then null;
end;
/
show errors

exec content_type.register_mime_type ('content_template', 'text/html');
exec content_type.register_mime_type ('content_template', 'text/plain');
