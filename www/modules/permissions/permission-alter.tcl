request create
request set_param object_id -datatype integer 
request set_param grantee_id -datatype integer
request set_param return_url -datatype text -optional
request set_param passthrough -datatype text -optional
request set_param ext_passthrough -datatype text -optional -value $passthrough

set user_id [User::getID]

db_1row get_info "" -column_array info

if { [string equal $info(user_cm_perm) t] } {

  form create own_permissions 
  content::perm_form_generate own_permissions \
   { ext_passthrough return_url } 
  content::perm_form_process own_permissions 

  if { [form is_valid own_permissions] && ![util::is_nil return_url] } {
    template::query::flush_cache "content::check_access ${grantee_id}*"
    template::forward "$return_url?[content::url_passthrough $ext_passthrough]"
  }
}

