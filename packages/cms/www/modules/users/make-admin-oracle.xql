<?xml version="1.0"?>

<queryset>
   <rdbms><type>oracle</type><version>8.1.6</version></rdbms>

<fullquery name="grant_permission">      
      <querytext>
      
  declare
    cursor c_module_cur is
      select module_id from cm_modules;
    v_module_id cm_modules.module_id%TYPE;
  begin
    open c_module_cur;
    loop
      fetch c_module_cur into v_module_id;
      exit when c_module_cur%NOTFOUND;
      cms_permission.grant_permission (
        v_module_id, :user_id, 'cm_admin', :target_user_id, 't'
      );
    end loop;
    close c_module_cur;

    cms_permission.grant_permission (
      content_item.get_root_folder, :user_id, 'cm_admin', :target_user_id, 't'
    );

    cms_permission.grant_permission (
      content_template.get_root_folder, :user_id, 'cm_admin', :target_user_id, 't'
    );
  end;
      </querytext>
</fullquery>

 
</queryset>
