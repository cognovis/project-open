# wizard for registering widgets to content type attributes

request create
request set_param attribute_id -datatype integer
request set_param content_type -datatype keyword
request set_param widget -datatype keyword -optional

set module_id [db_string get_module_id ""]

# permissions check - need cm_write on types module to edit a widget
content::check_access $module_id cm_write -user_id [User::getID] 


wizard set_param attribute_id $attribute_id
wizard set_param content_type $content_type
if { ![template::util::is_nil widget] } {
  wizard set_param widget $widget
}


wizard create -action "index?id=$content_type" -params {
    attribute_id content_type widget
} -steps {
    1 -label "Choose a widget"      -url "widget-register-1"
    2 -label "Edit Widget Params"   -url "widget-register-2"
    3 -label "Preview Widget"       -url "widget-register-3" 
}
wizard set_finish_url [export_vars -base index { { id $content_type } }]

wizard get_current_step
