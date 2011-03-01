
# @namespace widget

# Procedures for generating and processing metadata form widgets, editing
# attribute widgets

namespace eval widget {}



ad_proc -public widget::param_element_create { form param order param_id \
	{default ""} {is_required ""} {param_source ""}} {

  @public param_element_create
  Dipatches subprocs to generate the form elements for
    setting an attribute widget param

  @param form Name of the form in which to generate the form elements

  @param param Name of the form widget param for which to generate a
  form element

  @param order The order that the param form widget will appear in the form

  @param param_id The ID of the form widget param

  @param default The default value of the form widget param

  @param is_required Flag indicating whether the form widget param is
  optional or required

  @param param_source The default source of the value of the form widget
  param.  One of literal, eval, query

} {

    template::element create $form param_$order \
	    -datatype keyword \
	    -widget hidden \
	    -value $param

    switch -exact -- $param {
	options { create_options_param $form $order \
		$default $is_required $param_source }
	values  { create_values_param $form $order \
		$default $is_required $param_source }
	default { create_text_param $form $order $default \
		$is_required $param_source }
    }
}



ad_proc -private widget::create_param_type { form order } {

  @private create_param_type

  Create default param_type form widget for adding/editing 
  metadata form widgets

  @author Michael Pih

  @param form The name of the form
  @param order The order of placement of the form widget within the form

} {
    template::element create $form param_type_$order \
	    -datatype keyword \
	    -widget select \
	    -label "Param Type" \
	    -options {
	       {onevalue onevalue}
	       {onelist onelist} 
	       {multilist multilist}
    }
}



ad_proc -private widget::create_param_source { form order param_source } {

  @private create_param_source

  Create default param_source form widget for adding/editing metadata
  form widgets

  @author Michael Pih

  @param form
  @param order The order of placement of the form widget within the form
  @param param_source The default param source of the metadata widget
         (literal, query, eval) 

} {
    template::element create $form param_source_$order \
	    -datatype keyword \
	    -widget select \
	    -label "Param Source" \
	    -options {{literal literal} {query query} {eval eval}} \
	    -values $param_source
}


ad_proc -private widget::create_param_value { form order default is_required } {

  @private create_param_value

  Create default param_value form widget for adding/editing metadata form
  widgets

  @author Michael Pih

  @param form The name of the form
  @param order The order of placement of the form widget within the form
  @param is_required A flag indicating whether the value of the form widget
         param is mandatory

} {

    if { ![template::util::is_nil is_required] } {
	template::element create $form param_value_$order \
		-datatype text \
		-widget textarea \
		-html { rows 4 cols 40 wrap physical } \
		-label "Param Values" \
		-value $default \
		-optional
    } else {
	template::element create $form param_value_$order \
		-datatype text \
		-widget textarea \
		-html { rows 4 cols 40 wrap physical } \
		-label "Widget Param Values" \
		-value $default
	
    }
}


ad_proc -private widget::create_text_param { form order default is_required param_source} {

  @private create_text_param

  Create default text param form widget for adding/editing metadata form
  widgets

  @author Michael Pih

  @param form The name of the form
  @param default The default value for the form widget param value
  @param is_required A flag indicating whether the value of the form widget
         param is mandatory
  @param param_source The deafult param source for the form widget param 
          value (literal, query, eval)

} {
    template::element create $form param_type_$order \
	    -datatype keyword \
	    -widget hidden \
	    -value "onevalue"

    widget::create_param_source $form $order $param_source
    widget::create_param_value $form $order $default $is_required
}





ad_proc -private widget::create_options_param { form order default is_required \
	param_source} {

  @private create_options_param

  Create the options param form widget for adding/editing metadata form
  widgets

  @author Michael Pih

  @param form The name of the form
  @param order The order of placement of the form widget within the form
  @param default The default value of the form widget param value
  @param is_required A flag indicating whether the form widget param
         value is mandatory
  @param param_source The default param source for the form widget param 
          value (literal, query, eval)

} {
    
    template::element create $form param_type_$order \
	    -datatype keyword \
	    -widget hidden \
	    -value "multilist"

    widget::create_param_source $form $order $param_source
    widget::create_param_value $form $order $default $is_required
}



ad_proc -private widget::create_values_param { form order default is_required param_source} {

  @private create_values_param

  Create the values param form widget for adding/editing metadata widgets

  @author Michael Pih

  @param form The name of the form
  @param order The order of placement of the form widget within the 
         metadata form
  @param default The default value of the form widget param value
  @param is_required A flag indicating whether the form widget param value
         is mandatory
  @param param_source The default param_source for the form widget param 
         value (literal, query, eval)

} {
    
    template::element create $form param_type_$order \
	    -datatype keyword \
	    -widget hidden \
	    -value "onelist"

    widget::create_param_source $form $order $param_source
    widget::create_param_value $form $order $default $is_required
}





ad_proc -private widget::process_param { form order content_type attribute_name } {    

  @private process_param

  Edits a metadata form widget parameter from the form

  @author Michael Pih

  @param db A database handle
  @param form The name of the form
  @param order The order of placement of the param form widgets within the form
  @param content_type The content type to which the attribute belongs
  @param attribute_name The name of the attribute

} {
    template::form get_values $form \
	    param_$order param_type_$order \
	    param_source_$order param_value_$order
 

    db_exec_plsql pp_proces_param "
      begin
      cm_form_widget.set_attribute_param_value (
          content_type   => :content_type,
          attribute_name => :attribute_name,
          param          => :param_$order,
          param_type     => :param_type_$order,
          param_source   => :param_source_$order,
          value          => :param_value_$order
      );
      end;"
}















# @namespace cm_widget

# Procedures associated with custom metadata widgets for basic CR 
# content types

namespace eval cm_widget {}



ad_proc -private cm_widget::validate_description { value } {

  @private validate_description

  Make sure that description <= 4000 bytes

  @author Michael Pih

  @param value The submitted value of the description form element

} {

    set result 1
    if { [string bytelength $value] > 4000 } {
	set result 0
    }
    return $result
}
