<?xml version="1.0"?>

<queryset>
   <rdbms><type>postgresql</type><version>7.1</version></rdbms>

<fullquery name="grant_permission">      
      <querytext>

  declare
    c_module_cur         record;
  begin
    for c_module_cur in select module_id from cm_modules
    loop
      PERFORM cms_permission__grant_permission (
        c_module_cur.module_id, :user_id, 'cm_admin', :target_user_id, 't'
      );
    end loop;

    PERFORM cms_permission__grant_permission (
      content_item__get_root_folder(null), :user_id, 'cm_admin', :target_user_id, 't'
    );

    PERFORM cms_permission__grant_permission (
      content_template__get_root_folder(), :user_id, 'cm_admin', :target_user_id, 't'
    );

    return null;
  end;
      </querytext>
</fullquery>

 
</queryset>
