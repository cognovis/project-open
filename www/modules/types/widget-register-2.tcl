# register a widget to an attribute

request create
request set_param attribute_id -datatype integer
request set_param widget -datatype keyword

form create widget_register -elements {
    content_type_pretty -datatype text -widget inform -label "Content Type"
    attribute_name_pretty -datatype text -widget inform -label "Attribute"
    widget_inform -datatype keyword -widget inform -label "Widget"
    content_type -datatype keyword -widget hidden
    attribute_name -datatype keyword -widget hidden
    widget -datatype keyword -widget hidden -param
    attribute_id -datatype integer -widget hidden -param
}


db_1row get_attr_info ""
element set_properties widget_register content_type_pretty \
	-value $content_type_pretty
element set_properties widget_register attribute_name_pretty \
	-value $attribute_name_pretty
element set_properties widget_register widget_inform \
	-value $widget
element set_properties widget_register content_type \
	-value $content_type
element set_properties widget_register attribute_name \
	-value $attribute_name


# get a list of params for this widget
set widget_params [db_list_of_lists get_params ""]


# create form sections and elements for each widget param
set i 0
foreach wparam $widget_params { 
    set param_id      [lindex $wparam 0]
    set param         [lindex $wparam 1]
    set is_required   [lindex $wparam 2]
    set is_html       [lindex $wparam 3]
    set default_value [lindex $wparam 4]
    set param_source  [lindex $wparam 5]

    form section widget_register "Param - $param"
    widget::param_element_create widget_register $param $i $param_id \
	    $default_value $is_required $param_source
    incr i
}

element create widget_register param_count \
	-datatype integer \
	-widget hidden \
	-value $i

wizard submit widget_register -buttons { back next }

# Process form

if { [form is_valid widget_register] } {
    form get_values widget_register \
	    content_type attribute_name param_count

    db_transaction {

        for { set i 0 } { $i < $param_count } { incr i } {
            widget::process_param  \
		widget_register $i $content_type $attribute_name
        }
    }

    wizard forward
}
