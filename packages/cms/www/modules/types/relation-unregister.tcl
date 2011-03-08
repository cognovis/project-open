# relation-unregister.tcl
# Unregister a relation type from a content type
# @author Michael Pih

request create
request set_param rel_type -datatype keyword -value item
request set_param content_type -datatype keyword
request set_param target_type -datatype keyword
request set_param relation_tag -datatype text -value ""

set module_id [db_string get_module_id ""]

# permissions check - must have cm_write on the types module
content::check_access $module_id cm_write -user_id [User::getID]

if { [string equal $rel_type child_rel] } {

    set unregister_method "unregister_child_type"
    set content_key "parent_type"
    set target_key "child_type"

} elseif { [string equal $rel_type item_rel] } {

    set unregister_method "unregister_relation_type"
    set content_key "content_type"
    set target_key "target_type"

} else {
    # bad rel_type, don't do anything
    template::forward "index?id=$content_type"
}


if { [catch {db_exec_plsql unregister "
      begin
      content_type.${unregister_method} (
          $content_key  => :content_type,
          $target_key   => :target_type,
          relation_tag  => :relation_tag
      );
      end;"} errmsg] } {
    template::request::error unregister_relation_type \
	    "Could not unregister relation type - $errmsg"
}

template::forward "index?id=$content_type"
