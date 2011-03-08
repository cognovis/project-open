request create
request set_param attribute_id -datatype integer


# permissions check - must have cm_write on the types module to unregister
#  a widget
set module_id [db_string get_module_id ""]

content::check_access $module_id cm_write -user_id [User::getID]

db_1row get_attr_info ""

if { [catch {db_exec_plsql unregister "
  begin
  cm_form_widget.unregister_attribute_widget (
      content_type   => :content_type,
      attribute_name => :attribute_name
  );
  end;
"} errmsg] } {
  template::request::error unregister_attribute_widget $errmsg
}


template::forward index?id=$content_type
