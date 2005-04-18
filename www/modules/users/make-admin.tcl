# Make some user a total administrator for everything
request create
request set_param target_user_id -datatype integer
request set_param mount_point -datatype keyword -value users
request set_param parent_id -datatype keyword -optional
request set_param return_url -datatype text -optional \
  -value "../$mount_point"

# The current user must have cm_admin on the users module in order
# to do this
set user_id [User::getID]

db_transaction {

    content::check_access [cm::modules::sitemap::getRootFolderID] "cm_admin" \
        -mount_point $mount_point -parent_id $parent_id 

    # Grant cm_admin on sitemap, templates, users

    db_exec_plsql grant_permission "
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
  end;"
}

template::forward $return_url
