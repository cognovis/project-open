# register a widget to an attribute

request create
request set_param attribute_id -datatype integer
request set_param widget -datatype keyword -optional

set step [wizard current_step]
set last_step [expr $step-1]
set back_url [wizard get_forward_url $last_step]

# no widget, no form
if { [template::util::is_nil widget] } {
    return
}


# the preview form
form create widget_preview
wizard submit widget_preview -buttons { back finish }

if { [form is_request widget_preview] } {

    set outstanding_params_list [db_list get_outstanding ""]
 
    # the number of required widget params that are missing
    set outstanding_params [llength $outstanding_params_list]

    db_1row get_name ""
    content::add_attribute_element widget_preview $object_type $attribute_name
}

if { [form is_valid widget_preview] } {
    form get_values widget_preview
    wizard forward
}

