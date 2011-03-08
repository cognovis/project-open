request create
request set_param rel_type     -datatype keyword
request set_param content_type -datatype keyword -value content_revision


set module_id [db_string get_module_id ""]

# permissions check - must have cm_write on the types module
content::check_access $module_id cm_write -user_id [User::getID]

form create relation -elements {
    rel_type     -datatype keyword -widget hidden -param
    content_type -datatype keyword -widget hidden -param
}

if { [string equal $rel_type item_rel] } {
    set rel_type_pretty "Item"
    set type_label "Related Object Type"

} elseif { [string equal $rel_type child_rel] } {
    set rel_type_pretty "Child"
    set type_label "Child Content Type"

} else {
    template::forward index?id=$content_type
}

set pretty_name [db_string get_pretty_name ""]

set target_types [db_list_of_lists get_target_types ""]

element create relation target_type \
	-datatype keyword \
	-widget select \
	-options $target_types \
	-label $type_label

element create relation relation_tag \
	-datatype text \
	-html { size 30 } \
	-label "Relation Tag"

element create relation min_n \
	-datatype integer \
	-html { size 4 } \
	-label "Min Relations"

element create relation max_n \
	-datatype integer \
	-html { size 4 } \
	-label "Max Relations (optional)" \
	-optional








if { [form is_valid relation] } {
    form get_values relation \
	    rel_type content_type target_type relation_tag min_n max_n

    # max_n should be null
    if { [template::util::is_nil max_n] } {
	set max_n ""
    }

    if { [string equal $rel_type item_rel] } {
        set register_method "register_relation_type"
        set content_key "content_type"
        set target_key "target_type"

    } elseif { [string equal $rel_type child_rel] } {
        set register_method "register_child_type"
        set content_key "parent_type"
        set target_key "child_type"
    }

    db_transaction {

        if { [catch {db_exec_plsql register_rel_types "
	  begin
          content_type.${register_method} (
	      $content_key => :content_type,
	      $target_key  => :target_type,
	      relation_tag => :relation_tag,
              min_n        => :min_n,
              max_n        => :max_n
          );
          end;"} errmsg] } {
            template::request::error register_relation_type \
		"Could not register relation type - $errmsg"
        }
    }    

    template::forward "index?id=$content_type"
}
