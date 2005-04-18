# register a widget to an attribute

request create
request set_param attribute_id -datatype integer


form create widget_register -elements {
    content_type_pretty -datatype text -widget inform -label "Content Type"
    attribute_name_pretty -datatype text -widget inform -label "Attribute"
    attribute_id -datatype integer -widget hidden -param
    content_type -datatype keyword -widget hidden
    attribute_name -datatype keyword -widget hidden
}


set form_widgets [db_list_of_lists get_form_widgets "" ]

element create widget_register widget \
    -datatype keyword \
    -widget select \
    -options $form_widgets \
    -label "Form Widget"

element create widget_register is_required \
    -datatype keyword \
    -widget radio \
    -label "Is Required?" \
    -options { {Yes t} {No f} }

wizard submit widget_register -buttons { next }


if { [form is_request widget_register] } {

    db_1row get_attr_info ""

    db_0or1row get_reg_widget ""

    element set_properties widget_register content_type_pretty \
        -value $content_type_pretty
    element set_properties widget_register attribute_name_pretty \
        -value $attribute_name_pretty

    element set_properties widget_register attribute_name \
        -value $attribute_name
    element set_properties widget_register content_type \
        -value $content_type

    if { ![template::util::is_nil registered_widget] } {
	element set_properties widget_register widget \
            -values $registered_widget
	element set_properties widget_register is_required \
            -values $is_required
    }
}





if { [form is_valid widget_register] } {

    form get_values widget_register \
        widget is_required attribute_name content_type

    db_transaction {

        set already_registered [db_string check_registered "" -default ""]

        # just update the is_required column if this widget is already registered
        #   this way we don't overwrite the existing attribute widget params
        if { ![string equal $already_registered ""] && \
                 $already_registered } {
            db_dml update_widgets ""
        } else {

            # (re)register a widget to an attribute
            db_exec_plsql register_widget ""
        }
    }
    
    wizard set_param widget $widget
    wizard forward
} else {

    db_1row get_attr_info ""

    element set_properties widget_register content_type_pretty \
        -value $content_type_pretty
    element set_properties widget_register attribute_name_pretty \
        -value $attribute_name_pretty
}
