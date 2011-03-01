ad_library {

    Support procs for the ams package

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-09-28
    @cvs-id $Id: ams-widget-procs.tcl,v 1.3 2009/03/21 18:14:12 cvs Exp $

}

namespace eval ams {}
namespace eval ams::widget {}
namespace eval ams::util {}
namespace eval ams::attribute::save {}
namespace eval ams::attributes::save {}

ad_proc -public ams::widget {
    -widget:required
    -request:required
    {-attribute_id ""}
    {-attribute_name ""}
    {-pretty_name ""}
    {-form_name ""}
    {-value ""}
    {-optional_p "1"}
    {-locale ""}
    {-html_options ""}
} {
    @param widget the <a href="/api-doc/proc-search?show_deprecated_p=0&query_string=ams::widget::&source_weight=0&param_weight=3&name_weight=5&doc_weight=2&show_private_p=1&search_type=All+matches">ams::widget::${widget}</a> we defer to
    @param request
    must be one of the following:
    <ul>
    <li><strong>ad_form_widget</strong> - returns element(s) string(s) suitable for inclusion in the form section of <a href="/api-doc/proc-view?proc=ad_form">ad_form</a></li>
    <li><strong>template_form_widget</strong> - </li>
    <li><strong>form_set_value</strong> - sets the form value(s), in both ad_form and template_form using the <a href="/api-doc/proc-view?proc=template::element::set_value">template::element::set_value</a> proc</li>
    <li><strong>form_save_value</strong> - saves the form value(s), and returns a value_id suitable for inclusion in the ams_attribute_values table. This value_id can be an object_id or any other integer id. The value id is used by the value_method command to get a value suitable for use with ams::widget procs.</li>
    <li><strong>value_text</strong> - returns the value formatted as text/plain</li>
    <li><strong>value_html</strong> - returns the value formatted as text/html</li>
    <li><strong>value_list_html</strong> - returns a list of sub_attributes that can be converted to an array with <code>array set myarray \$list</code> where the value formatted as text/html. If no sub_attributes exists then nothing should be returned. For example with a postal_address this would return a list of <code>delivery_address {1234 Main Street} region {CA} country {United States}</code> etc.</li>
    <li><strong>value_list_text</strong> - returns a list of sub_attributes that can be converted to an array with <code>array set myarray \$list</code> where the value formatted as text/plain. If no sub_attributes exists then nothing should be returned. For example with a postal_address this would return a list of <code>delivery_address {1234 Main Street} region {CA} country {United States}</code> etc.</li>
    <li><strong>value_list_headings</strong> - returns a list of sub_attributes and their pretty names. e.g. for postal_address in en_US: <code>delivery_address {Steet} region {State/Province}</code> etc.
    <li><strong>csv_value</strong> - not yet implemented</li>
    <li><strong>csv_headers</strong> - not yet implemented</li>
    <li><strong>csv_save</strong> - not yet implemented</li>
    <li><strong>widget_datetypes</strong> - the acs_datatype(s) associated with this widget</li>
    <li><strong>widget_name</strong> - a pretty (human readable) name for this widget</li>
    <li><strong>value_method</strong> - the name of a database procedure to be called when returning a value to this procedure. The procedure will only get the value_id supplied in the form_save_value request and must convert that to whatever format it wants. In the simplest case it would return the value_id itself and then when you use form_set_value, value_text, value_html, csv_value actions a trip would need to be made to the database to return the appropriate values. If at all possible this procedure should return all the information necessary to format the value with this procedure (and thus not require another trip to the database which would siginifcantly decrease performance).</li>
    </ul>
    @param attribute_name
    @param pretty_name The name for the widget or to be used as a description of the attribute value
    @param form_name The name of the template_form or ad_form being used
    @param value The attribute value to be manipulated by this widget
    @param optional_p Whether or not an answer to this widget is required
} {

    if { [::ams::widget_proc_exists_p -widget $widget] } {
        switch $request {
            ad_form_widget - template_form_widget - form_save_value {
		if { [::ams::widget_has_options_p -widget $widget] } {
		    set options [::ams::widget_options -attribute_id $attribute_id]
		} else {
		    set options {}
		}
	    }
            value_text - value_html {
                if { [exists_and_not_null value] } {
                    if { [::ams::widget_has_options_p -widget $widget] } {
                        set output [list]
                        foreach option [::ams::widget_options -attribute_id $attribute_id -locale $locale] {
                            if { [lsearch $value [lindex $option 1]] >= 0 } {
                                lappend output [lindex $option 0]
                            }
                        }
                        set value [join $output "\n"]
                    }
                }
                set options {}
            }
	    default {
		set options {}
	    }
	}

	return [::ams::widget::${widget} -request $request -attribute_name $attribute_name -pretty_name $pretty_name -value $value -optional_p $optional_p -form_name $form_name -options $options -attribute_id $attribute_id -html_options $html_options]

    } else {

	# The widget does not exist in AMS
	# Try with DynField widgets

	return [im_dynfield::widget_request -widget $widget -request $request -attribute_name $attribute_name -pretty_name $pretty_name -value $value -optional_p $optional_p -form_name $form_name -attribute_id $attribute_id -html_options $html_options]
	
    }
}

ad_proc -private ams::widget_options {
    -attribute_id:required
    {-locale ""}
} {
    Return all widget procs. Each list element is a list of the first then pretty_name then the widget. Cached
} {
    return [util_memoize [list ams::widget_options_not_cached -attribute_id $attribute_id -locale $locale]]
}

ad_proc -private ams::widget_options_not_cached {
    -attribute_id:required
    {-locale ""}
} {
    Return all widget procs. Each list element is a list of the first then pretty_name then the widget
} {
    set return_list [list]
    db_foreach get_options {} {
	set pretty_name "[lang::util::localize $pretty_name $locale]"
	lappend return_list [list $pretty_name $option_id]
    }
    return $return_list
}

ad_proc -private ams::widget_options_flush {
    -attribute_id:required
} {
    flush ams::widget_options_not_cached
} {
    util_memoize_flush_regexp "ams::widget_options_not_cached(.*?)$attribute_id"
}

ad_proc -private ams::widget_list {
} {
    Return all widget procs. Each list element is a list of the first then pretty_name then the widget
} {
    set widgets [list]
    set all_procs [::info procs "::ams::widget::*"]
    foreach widget $all_procs {
			 if { [string is false [regsub {__arg_parser} $widget {} widget]] } {
			     regsub {::ams::widget::} $widget {} widget
			     lappend widgets [list [::ams::widget -widget $widget -request "widget_name"] $widget]
			 }
 }
    return $widgets
}

ad_proc -private ams::widgets_init {
} {
    Initialize all widgets.
} {
    set proc_widgets [list]
    foreach widget [ams::widget_list] {
	lappend proc_widgets [lindex $widget 1]
    }
    set sql_list_of_valid_procs "'[join $proc_widgets {','}]'"
    db_transaction {
        db_foreach select_widgets_to_deactivate "" {
	    set active_p 0
	    db_1row save_widget {}
	}
        foreach widget $proc_widgets {
            # is the widget in the database?
            set pretty_name  [ams::widget -widget $widget -request "widget_name"]
            set value_method [ams::widget -widget $widget -request "value_method"]
            set active_p 1
            db_1row save_widget {}
        }
    }
}

ad_proc -private ams::widget_proc_exists_p {
    -widget:required
} {
    Does the procedure ams::widget::\${widget} exist?

    @return 0 if false 1 if true
} {
    return [string is false [empty_string_p [info procs "::ams::widget::${widget}"]]]
}

ad_proc -private ams::widget_has_options_p {
    -widget:required
} {
    Is the procedure ams::widget::\${widget} one that depends on options?

    @return 0 if false 1 if true
} {
    if { [ams::widget_proc_exists_p -widget $widget] } {
	if { [ams::widget -widget $widget -request "value_method"] == "ams_value__options" } {
	    return 1
	} else {
	    return 0
	}
    } else {
	return 0
    }
}


ad_proc -private ams::widget::postal_address {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:address(address),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:address(address) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype address \
		    -widget address \
                    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype address \
		    -widget address \
                    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::postal_address_save \
			-delivery_address [template::util::address::get_property delivery_address $value] \
                        -municipality [template::util::address::get_property municipality $value] \
                        -region [template::util::address::get_property region $value] \
                        -postal_code [template::util::address::get_property postal_code $value] \
                        -country_code [template::util::address::get_property country_code $value] \
                        -additional_text [template::util::address::get_property additional_text $value] \
                        -postal_type [template::util::address::get_property postal_type $value]]
	}
        value_text {
            util_unlist $value delivery_address municipality region postal_code country_code additional_text postal_type
	    return [ad_html_to_text -showtags -no_format [template::util::address::html_view $delivery_address $municipality $region $postal_code $country_code $additional_text $postal_type]]
	}
        value_html {
            util_unlist $value delivery_address municipality region postal_code country_code additional_text postal_type
	    return [template::util::address::html_view $delivery_address $municipality $region $postal_code $country_code $additional_text $postal_type]
	}
	value_list_text {
            util_unlist $value delivery_address municipality region postal_code country_code additional_text postal_type

	    # in addition to the standard postal_address attributes we also return 
	    # the country - which is automatically localized for the user, since
            # most programs would want it anyways
	    set country [template::util::address::country -country_code $country_code]
	    return [list delivery_address $delivery_address municipality $municipality region $region postal_code $postal_code country_code $country_code additional_text $additional_text postal_type $postal_type country $country]
	}
	value_list_html {
            util_unlist $value delivery_address municipality region postal_code country_code additional_text postal_type

	    # in addition to the standard postal_address attributes we also return 
	    # the country - which is automatically localized for the user, since
            # most programs would want it anyways
	    set country [template::util::address::country -country_code $country_code]

	    set delivery_address [ad_html_text_convert -from "text/plain" -to "text/html" -- $delivery_address]
	    set municipality [ad_html_text_convert -from "text/plain" -to "text/html" -- $municipality]
	    set region [ad_html_text_convert -from "text/plain" -to "text/html" -- $region]
	    set postal_code [ad_html_text_convert -from "text/plain" -to "text/html" -- $postal_code]
	    # country_code is two characters and doesn't need to be converted
	    # country shouldn't need to be converted
	    # not in use no need for overhead:
	    # set additional_text [ad_html_text_convert -from "text/plain" -to "text/html" -- $additional_text]
	    # set postal_type [ad_html_text_convert -from "text/plain" -to "text/html" -- $postal_type]

	    return [list delivery_address $delivery_address municipality $municipality region $region postal_code $postal_code country_code $country_code additional_text $additional_text postal_type $postal_type country $country]
	}
	value_list_headings {
	    # this returns the pretty names for the results returned by the value_list
            # this is used by contracting packages to get pretty_names for attributes
            # of postal_address. The list is in the order in which the user would
            # expect to encounter these attributes... i.e. in a csv list, form, etc.
	    #
            # we are not including additional_text or postal_type here
            # because they are either are not implemented in the widget
            # country code is not returned because most users are happy
            # with the country and having both country and country_code
            # can be confusing
	    return [list delivery_address [_ intranet-dynfield.delivery_address] municipality [_ intranet-dynfield.municipality] region [_ intranet-dynfield.region] postal_code [_ intranet-dynfield.postal_code] country [_ intranet-dynfield.country]]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "string"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Address"]
	}
	value_method {
	    return "ams_value__postal_address"
	}
    }
}


ad_proc -private ams::widget::telecom_number {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:telecom_number(telecom_number),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:telecom_number(telecom_number) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype telecom_number \
		    -widget telecom_number \
                    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype telecom_number \
		    -widget telecom_number \
                    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} $value
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::telecom_number_save \
			-itu_id [template::util::telecom_number::get_property itu_id $value] \
			-national_number [template::util::telecom_number::get_property national_number $value] \
			-area_city_code [template::util::telecom_number::get_property area_city_code $value] \
			-subscriber_number [template::util::telecom_number::get_property subscriber_number $value] \
			-extension [template::util::telecom_number::get_property extension $value] \
			-sms_enabled_p [template::util::telecom_number::get_property sms_enabled_p $value] \
			-best_contact_time [template::util::telecom_number::get_property best_contact_time $value] \
			-location [template::util::telecom_number::get_property location $value] \
			-phone_type_id [template::util::telecom_number::get_property phone_type_id $value]]
	}
        value_text {
	    util_unlist $value itu_id national_number area_city_code subscriber_number extension sms_enabled_p best_contact_time location phone_type_id
	    return [ad_html_to_text -showtags -no_format [template::util::telecom_number::html_view $itu_id $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time $location $phone_type_id]]
	}
        value_html {
	    util_unlist $value itu_id national_number area_city_code subscriber_number extension sms_enabled_p best_contact_time location phone_type_id
	    return [template::util::telecom_number::html_view $itu_id $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time $location $phone_type_id]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "string"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Telecom_Number"]
	}
	value_method {
	    return "ams_value__telecom_number"
	}
    }
}

ad_proc -private ams::widget::mobile_number {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {
    if { [llength $html_options] == 0 } {
	set html_options [list]
    }
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    set element [list]
	    if { [string is true $optional_p] } {
		return "${attribute_name}:mobile_number(mobile_number),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:mobile_number(mobile_number) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	    return $element
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype telecom_number \
		    -widget mobile_number \
		    -optional \
		    -html $html_options
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype telecom_number \
		    -widget mobile_number \
		    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} $value
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::telecom_number_save \
			-itu_id [template::util::mobile_number::get_property itu_id $value] \
			-national_number [template::util::mobile_number::get_property national_number $value] \
			-area_city_code [template::util::mobile_number::get_property area_city_code $value] \
			-subscriber_number [template::util::mobile_number::get_property subscriber_number $value] \
			-extension [template::util::mobile_number::get_property extension $value] \
			-sms_enabled_p [template::util::mobile_number::get_property sms_enabled_p $value] \
			-best_contact_time [template::util::mobile_number::get_property best_contact_time $value] \
			-location [template::util::mobile_number::get_property location $value] \
			-phone_type_id [template::util::mobile_number::get_property phone_type_id $value]]
	}
        value_text {
	    util_unlist $value itu_id national_number area_city_code subscriber_number extension sms_enabled_p best_contact_time location phone_type_id
	    return [template::util::mobile_number::text_view $itu_id $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time $location $phone_type_id]]
	}
        value_html {
	    util_unlist $value itu_id national_number area_city_code subscriber_number extension sms_enabled_p best_contact_time location phone_type_id
	    return [template::util::mobile_number::html_view $itu_id $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time $location $phone_type_id]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "string"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Mobile_Number"]
	}
	value_method {
	    return "ams_value__telecom_number"
	}
    }
}

ad_proc -private ams::widget::aim {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {
    set value [ams::util::text_value -value $value]
    if { [llength $html_options] == 0 } {
	set html_options [list]
    }
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    set element [list]
	    if { [string is true $optional_p] } {
		lappend element ${attribute_name}:text(text),optional 
	    } else {
		lappend element ${attribute_name}:text(text)
	    }
	    lappend element [list label ${pretty_name}]
	    lappend element [list html $html_options]
	    lappend element [list help_text $help_text]
	    return $element
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype text \
		    -widget text \
		    -optional \
		    -html $html_options
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype text \
		    -widget text \
		    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} $value
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::text_save -text $value -text_format "text/plain"]
	}
        value_text {
#	    set status [template::util::aim::status -username $value]
#
            # getting the status can take too long. so we return it for html views
            # but do not return it for text. This is in part because text exports 
            # are often used for csv export and the like.
	    return $value
	}
        value_html {
#	    switch $status {
#		"online"  {set status_html "<img src=\"/resources/ams/aim_online.gif\" alt\"online\" />"}
#		"offline" {set status_html "<img src=\"/resources/ams/aim_offline.gif\" alt=\"offline\" />"}
#		default   {set status_html "Not A Valid ID"}
#	    }
	    return "$value [template::util::aim::status_img -username $value]"
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "string"]
	}
	widget_name {
	    return [_ "intranet-dynfield.AIM"]
	}
	value_method {
	    return "ams_value__text"
	}
    }
}

ad_proc -private ams::widget::skype {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {
    set value [ams::util::text_value -value $value]
    if { [llength $html_options] == 0 } {
	set html_options [list]
    }
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    set element [list]
	    if { [string is true $optional_p] } {
		lappend element ${attribute_name}:text(text),optional 
	    } else {
		lappend element ${attribute_name}:text(text)
	    }
	    lappend element [list label ${pretty_name}]
	    lappend element [list html $html_options]
	    lappend element [list help_text $help_text]
	    return $element
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype text \
		    -widget text \
		    -optional \
		    -html $html_options
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype text \
		    -widget text \
		    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} $value
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::text_save -text $value -text_format "text/plain"]
	}
        value_text {
	    set status [template::util::skype::status_txt -username $value]
	    return "$value - $status"
	}
        value_html {
	    set status [template::util::skype::status_img -username $value -image_type "small_icon"]
	    return "$value $status"
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "string"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Skype"]
	}
	value_method {
	    return "ams_value__text"
	}
    }
}



ad_proc -private ams::widget::date {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {

    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:date(date),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:date(date) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype date \
		    -widget date \
                    -html $html_options \
		    -help \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype date \
		    -widget date \
                    -html $html_options \
		    -help
	    }
	}
        form_set_value {
            regsub -all {\-} $value { } value
            regsub -all {:} $value { } value
	    ::template::element::set_value ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::time_save -time [template::util::date::get_property ansi $value]]
	}
	value_text {
	    return [lc_time_fmt $value %x]
	}
	value_html {
	    return [lc_time_fmt $value %q]
	}
        value_list_text - value_list_html {
	    if { $request == "value_list_text" } {
		set date [lc_time_fmt $value %x]
	    } else {
		set date [lc_time_fmt $value %q]
	    }
	    set year [lc_time_fmt $value %Y]
	    set month [lc_time_fmt $value "%m (%b)"]
	    return [list date $date year $year month $month]
	}
	value_list_headings {
	    return [list date [_ intranet-dynfield.Date] month [_ acs-templating.Month] year [_ acs-templating.Year]]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "date"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Date"]
	}
	value_method {
	    return "ams_value__time"
	}
    }
}

ad_proc -private ams::widget::textdate {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {
    if { $value ne "" } {
	# we are fed a full date (with timestamp and time zone,
        # so we set the value as only the yyyy-mm-dd part
	regexp {^([0-9]{4}-[0-9]{2}-[0-9]{2})} $value match value
    }

    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:textdate(textdate),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:textdate(textdate) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype textdate \
		    -widget textdate \
                    -html $html_options \
		    -help \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype textdate \
		    -widget textdate \
                    -html $html_options \
		    -help
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::time_save -time ${value}]
	}
	value_text {
	    return [lc_time_fmt $value %x]
	}
	value_html {
	    return [lc_time_fmt $value %q]
	}
        value_list_text - value_list_html {
	    if { $request == "value_list_text" } {
		set date [lc_time_fmt $value %x]
	    } else {
		set date [lc_time_fmt $value %q]
	    }
	    set year [lc_time_fmt $value %Y]
	    set month [lc_time_fmt $value "%m (%b)"]
	    return [list date $date year $year month $month]
	}
	value_list_headings {
	    return [list date [_ intranet-dynfield.Date] month [_ acs-templating.Month] year [_ acs-templating.Year]]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "textdate"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Text_Date"]
	}
	value_method {
	    return "ams_value__time"
	}
    }
}

ad_proc -private ams::widget::select {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {

    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		set options [concat [list [list "" ""]] $options]
		return "${attribute_name}:integer(select),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]} {[list options $options]} {[list value [attribute::default_value -attribute_id $attribute_id]]}"
	    } else {
		set options [concat [list [list "- [_ intranet-dynfield.select_one] -" ""]] $options]
		return "${attribute_name}:integer(select) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]} {[list options $options]} {[list value [attribute::default_value -attribute_id $attribute_id]]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype integer \
		    -widget select \
                    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype integer \
		    -widget select \
                    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::options_save -options $value]
	}
        value_text {
	    return ${value}
	}
        value_html {
#	    return [ad_html_text_convert -from "text/plain" -to "text/html" -- ${value}]
	    return $value
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "string"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Select"]
	}
	value_method {
	    return "ams_value__options"
	}
    }
}


ad_proc -private ams::widget::radio {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {

    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:integer(radio),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]} {[list options $options]} {[list value [attribute::default_value -attribute_id $attribute_id]]}"
	    } else {
		return "${attribute_name}:integer(radio) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]} {[list options $options]} {[list value [attribute::default_value -attribute_id $attribute_id]]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype integer \
		    -widget radio \
                    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype integer \
		    -widget radio \
                    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::options_save -options $value]
	}
        value_text {
	    return ${value}
	}
        value_html {
	    return [ad_html_text_convert -from "text/plain" -to "text/html" -- ${value}]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "string"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Radio"]
	}
	value_method {
	    return "ams_value__options"
	}
    }
}


ad_proc -private ams::widget::checkbox {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {

    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:integer(checkbox),multiple,optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]} {[list options $options]} {[list value [attribute::default_value -attribute_id $attribute_id]]}"
	    } else {
		return "${attribute_name}:integer(checkbox),multiple {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]} {[list options $options]} {[list value [attribute::default_value -attribute_id $attribute_id]]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype integer \
		    -widget checkbox \
                    -html $html_options \
		    -multiple \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype integer \
		    -widget checkbox \
                    -html $html_options \
		    -multiple
	    }
	}
        form_set_value {
	    ::template::element::set_values ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set values [::template::element::get_values ${form_name} ${attribute_name}]
	    return [ams::util::options_save -options $values]
	}
        value_text {
	    return ${value}
	}
        value_html {
	    return [ad_html_text_convert -from "text/plain" -to "text/html" -- ${value}]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "string"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Checkbox"]
	}
	value_method {
	    return "ams_value__options"
	}
    }
}


ad_proc -private ams::widget::multiselect {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {

    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:integer(multiselect),multiple,optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]} {[list options $options]} {[list value [attribute::default_value -attribute_id $attribute_id]]}"
	    } else {
		return "${attribute_name}:integer(multiselect),multiple {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]} {[list options $options]} {[list value [attribute::default_value -attribute_id $attribute_id]]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype integer \
		    -widget multiselect \
		    -multiple \
                    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype integer \
		    -widget multiselect \
                    -html $html_options \
		    -multiple
	    }
	}
        form_set_value {
	    ::template::element::set_values ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set values [::template::element::get_values ${form_name} ${attribute_name}]
	    return [ams::util::options_save -options $values]
	}
        value_text {
	    return ${value}
	}
        value_html {
	    return [ad_html_text_convert -from "text/plain" -to "text/html" -- ${value}]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "string"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Multiselect"]
	}
	value_method {
	    return "ams_value__options"
	}
    }
}




ad_proc -private ams::widget::integer {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {

    if { $html_options == "" } {
	set html_options "size 6"
    }
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:integer(text),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:integer(text) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype integer \
		    -widget text \
		    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype integer \
		    -widget text \
		    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::number_save -number $value]
	}
        value_text {
	    return ${value}
	}
        value_html {
	    return [ad_html_text_convert -from "text/plain" -to "text/html" -- ${value}]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "integer"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Integer"]
	}
	value_method {
	    return "ams_value__number"
	}
    }
}


ad_proc -private ams::widget::textbox {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {

    set value [ams::util::text_value -value $value]
    if { $html_options == "" } {
	set html_options "size 30"
    }
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:text(text),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:text(text) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype text \
		    -widget text \
		    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype text \
		    -widget text \
		    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::text_save -text $value -text_format "text/plain"]
	}
        value_text {
	    return ${value}
	}
	value_html {
	    return [ad_html_text_convert -from "text/plain" -to "text/html" -- ${value}]
#	    return $value
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "string"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Textbox"]
	}
	value_method {
	    return "ams_value__text"
	}
    }
}


ad_proc -private ams::widget::textarea {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {
    set value [ams::util::text_value -value $value]
    if { $html_options == "" } {
	set html_options "cols 60 rows 6"
    }
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:text(textarea),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:text(textarea) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype text \
		    -widget textarea \
		    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype text \
		    -widget textarea \
		    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::text_save -text $value -text_format "text/plain"]
	}
        value_text {
	    return ${value}
	}
        value_html {
	    return [ad_html_text_convert -from "text/plain" -to "text/html" -- ${value}]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "text"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Textarea"]
	}
	value_method {
	    return "ams_value__text"
	}
    }
}


ad_proc -private ams::widget::richtext {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {
    set value_format [ams::util::text_format -value $value]
    set value [ams::util::text_value -value $value]
    if { $html_options == "" } {
	set html_options "cols 60 rows 14"
    }
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:richtext(richtext),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:richtext(richtext) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype richtext \
		    -widget richtext \
		    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype richtext \
		    -widget richtext \
		    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} [list ${value} ${value_format}]
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::text_save \
			-text [template::util::richtext::get_property contents $value] \
			-text_format [template::util::richtext::get_property format $value]]
	}
        value_text {
	    return [ad_html_text_convert -from $value_format -to "text/plain" -- ${value}]
	}
        value_html {
	    return [ad_html_text_convert -from $value_format -to "text/html" -- ${value}]
	}
	value_list_text {
	    return [list content [ad_html_text_convert -from $value_format -to "text/plain" -- ${value}] format $value_format]
	}
	value_list_html {
	    return [list content [ad_html_text_convert -from $value_format -to "text/html" -- ${value}] format $value_format]
	}
	value_list_headings {
	    return [list content [_ intranet-dynfield.Content] format [_ intranet-dynfield.Format]]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "text"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Richtext"]
	}
	value_method {
	    return "ams_value__text"
	}
    }
}


ad_proc -private ams::widget::email {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {
    set value [ams::util::text_value -value $value]
    if { $html_options == "" } {
	set html_options "size 30"
    }
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:email(text),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:email(text) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype email \
		    -widget text \
		    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype email \
		    -widget text \
		    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::text_save -text $value -text_format "text/plain"]
	}
        value_text {
	    return ${value}
	}
        value_html {
	    return [ad_html_text_convert -from "text/plain" -to "text/html" -- ${value}]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "email"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Email"]
	}
	value_method {
	    return "ams_value__text"
	}
    }
}


ad_proc -private ams::widget::url {
    -request:required
    -attribute_name:required
    -pretty_name:required
    -form_name:required
    -value:required
    -optional_p:required
    -options:required
    -attribute_id:required
    -html_options:required
} {
    This proc responds to the ams::widget procs.

    @see ams::widget
} {
    set value [ams::util::text_value -value $value]
    if { $html_options == "" } {
	set html_options "size 30"
    }
    switch $request {
        ad_form_widget  {
	    set help_text [attribute::help_text -attribute_id $attribute_id] 
	    if { [string is true $optional_p] } {
		return "${attribute_name}:url(text),optional {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    } else {
		return "${attribute_name}:url(text) {help_text \"$help_text\"} {[list label ${pretty_name}]} {[list html ${html_options}]}"
	    }
	}
        template_form_widget  {
	    if { [string is true $optional_p] } {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype url \
		    -widget text \
		    -html $html_options \
		    -optional
	    } else {
		::template::element::create ${form_name} ${attribute_name} \
		    -label ${pretty_name} \
		    -datatype url \
		    -widget text \
		    -html $html_options
	    }
	}
        form_set_value {
	    ::template::element::set_value ${form_name} ${attribute_name} ${value}
	}
        form_save_value {
	    set value [::template::element::get_value ${form_name} ${attribute_name}]
	    return [ams::util::text_save -text $value -text_format "text/plain"]
	}
        value_text {
	    return ${value}
	}
        value_html {
	    return [ad_html_text_convert -from "text/plain" -to "text/html" -- ${value}]
	}
        csv_value {
	    # not yet implemented
	}
        csv_headers {
	    # not yet implemented
	}
        csv_save {
	    # not yet implemented
	}
	widget_datatypes {
	    return [list "url"]
	}
	widget_name {
	    return [_ "intranet-dynfield.Url"]
	}
	value_method {
	    return "ams_value__text"
	}
    }
}

ad_proc -private ams::util::text_save {
    -text:required
    -text_format:required
} {
    return a value_id     
} {
    set text [string trim $text]
    set text_format [string trim $text_format]
    if { [exists_and_not_null text] } {
	return [db_string save_value {} -default {}]
    }
}

ad_proc -private ams::util::text_value {
    -value:required
} {
    return the value part of a text value
} {
    if { [empty_string_p $value] } {
	return ""
    } else {
	regexp -all "^\{(.*?)\} (.*)$" $value match format value
	set value [string trim $value]
	return $value
    }}

ad_proc -private ams::util::text_format {
    -value:required
} {
    return a the text part of a text value
} {
    if { [empty_string_p $value] } {
	return ""
    } else {
	regexp -all "^\{(.*?)\} (.*)$" $value match format value
	set format [string trim $format]
	return $format
    }
}

ad_proc -private ams::util::time_save {
    -time:required
} {
    return a value_id     
} {
    set time [string trim $time]
    if { [exists_and_not_null time] } {
	return [db_string save_value {} -default {}]
    }
}

ad_proc -private ams::util::number_save {
    -number:required
} {
    return a value_id     
} {
    set number [string trim $number]
    if { [exists_and_not_null number] } {
    return [db_string save_value {} -default {}]
    }
}

ad_proc -private ams::util::postal_address_save {
    {-delivery_address ""}
    {-municipality ""}
    {-region ""}
    {-postal_code ""}
    {-country_code ""}
    {-additional_text ""}
    {-postal_type ""}
} {
    Save the postal address in the postal_addresses table.
    If the country code is empty, do nothing

    @return a value_id     
} {
    set delivery_address [string trim $delivery_address]
    set municipality [string trim $municipality]
    set region [string trim $region]
    set postal_code [string trim $postal_code]
    set country_code [string trim $country_code]
    set additional_text [string trim $additional_text]
    set postal_type [string trim $postal_type]
    if {$country_code == ""} {
	return ""
    } else {
	return [db_string save_value {} -default {}]
    }
}

ad_proc -private ams::util::telecom_number_save {
    {-itu_id ""}
    {-national_number ""}
    {-area_city_code ""}
    -subscriber_number:required
    {-extension ""}
    {-sms_enabled_p ""}
    {-best_contact_time ""}
    {-location ""}
    {-phone_type_id ""}
} {
    return a value_id     
} {
    set itu_id [string trim $itu_id]
    set national_number [string trim $national_number]
    set area_city_code [string trim $area_city_code]
    set subscriber_number [string trim $subscriber_number]
    set extension [string trim $extension]
    set sms_enabled_p [string trim $sms_enabled_p]
    set best_contact_time [string trim $best_contact_time]
    set location [string trim $location]
    set phone_type_id [string trim $phone_type_id]
    if { [exists_and_not_null subscriber_number] } {
	return [db_string save_value {} -default {}]
    }
}

ad_proc -public ams::util::options_save {
    -options:required
} {
    Map an ams option for an attribute to an option_map_id, if no value is supplied for option_map_id a new option_map_id will be created.

    @param option_map_id
    @param option_id

    @return option_map_id
} {
    set options [lsort $options]
    set value_id [db_string options_value_id {} -default {}]
    if { [string is false [exists_and_not_null value_id]] } {
	foreach option_id $options {
	    if {![string eq "" $option_id]} {
		set value_id [db_string option_map {}]
	    }
	}
    }
    return $value_id
}


##########################################
# Quick Procs for Saving multiple values
##########################################

ad_proc -public ams::attributes::save::text {
    -object_id:required
    {-object_type ""}
    -value_list
} {
    Save Multiple values for an object_id
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-07-22
    
    @param object_id The object for which the value is stored
    
    @param value_list Pair List of attribute_id and value which will be inserted for the object_id

    @return
    
    @error
} {

    if {[string eq $object_type ""]} {
	set object_type [acs_object_type $object_id]
    }
    
    # Set the text attributes
    foreach pair $value_list {
	set value [lindex $pair 1]
	set attribute_name [lindex $pair 0]
	if {[exists_and_not_null value]} {
	    ams::attribute::save::text \
		-object_id $object_id \
		-attribute_name $attribute_name \
		-object_type $object_type \
		-value $value
	}
    }
}

ad_proc -public ams::attributes::save::phone {
    -object_id:required
    {-object_type ""}
    -value_list
} {
    Save Multiple phone values for an object_id
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-07-22
    
    @param object_id The object for which the value is stored
    
    @param value_list Pair List of attribute_id and value which will be inserted for the object_id

    @return
    
    @error
} {

    if {[string eq $object_type ""]} {
	set object_type [acs_object_type $object_id]
    }
    
    # Set phone attributes    

    foreach pair $value_list {
	set value [lindex $pair 1]
	set attribute_name [lindex $pair 0]
	if {[exists_and_not_null value]} {
	    set value_id [ams::util::telecom_number_save \
			      -subscriber_number $value
			 ]
	    set attribute_id [attribute::id \
				  -object_type $object_type \
				  -attribute_name $attribute_name
			     ]
	    ams::attribute::value_save \
		-attribute_id $attribute_id \
		-value_id $value_id \
		-object_id $object_id
	}
    }
}

ad_proc -public ams::attributes::save::number {
    -object_id:required
    {-object_type ""}
    -value_list
} {
    Save Multiple number values for an object_id
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-07-22
    
    @param object_id The object for which the value is stored
    
    @param value_list Pair List of attribute_id and value which will be inserted for the object_id

    @return
    
    @error
} {

    if {[string eq $object_type ""]} {
	set object_type [acs_object_type $object_id]
    }
    # Set phone attributes    

    foreach pair $value_list {
	set value [lindex $pair 1]
	set attribute_name [lindex $pair 0]
	if {[exists_and_not_null value]} {
	    set value_id [ams::util::number_save \
			      -number $value
			 ]
	    set attribute_id [attribute::id \
				  -object_type $object_type \
				  -attribute_name $attribute_name
			     ]
	    ams::attribute::value_save \
		-attribute_id $attribute_id \
		-value_id $value_id \
		-object_id $object_id
	}
    }
}

#########################
# Quick Procs for Saving
#########################

ad_proc -public ams::attribute::save::text {
    -object_id:required
    {-attribute_id ""}
    {-attribute_name ""}
    {-object_type ""}
    {-format "text/plain"}
    -value
} {
    Save the value of an AMS text attribute for an object.
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-07-22
    
    @param object_id The object for which the value is stored
    
    @param attribute_id The attribute_id of the attribute for which the value is retrieved
    
    @param attribute_name Alternatively the attribute_name for the attribute
    
    @return
    
    @error
} {
    if {[exists_and_not_null value]} {
	if {[empty_string_p $attribute_id]} {
	    set attribute_id [attribute::id \
				  -object_type "$object_type" -attribute_name "$attribute_name"]
	}
	if {[exists_and_not_null attribute_id]} {

	    set value_id [ams::util::text_save \
			      -text $value \
			      -text_format "text/plain"]
	    ams::attribute::value_save -object_id $object_id -attribute_id $attribute_id -value_id $value_id
	}
    }
}

ad_proc -public ams::attribute::save::number {
    -object_id:required
    {-attribute_id ""}
    {-attribute_name ""}
    {-object_type ""}
    {-format "text/plain"}
    -number
} {
    Save the value of an AMS text attribute for an object.
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-07-22
    
    @param object_id The object for which the value is stored
    
    @param attribute_id The attribute_id of the attribute for which the value is retrieved
    
    @param attribute_name Alternatively the attribute_name for the attribute
    
    @param number The number value to save
    @return
    
    @error
} {
    if {[exists_and_not_null value]} {
	if {[empty_string_p $attribute_id]} {
	    set attribute_id [attribute::id \
				  -object_type "$object_type" -attribute_name "$attribute_name"]
	}
	if {[exists_and_not_null attribute_id]} {
	    set value_id [ams::util::number_save -number $number]
	    ams::attribute::value_save -object_id $object_id -attribute_id $attribute_id -value_id $value_id
	}
    }
}

ad_proc -public ams::attribute::save::timestamp {
    -object_id:required
    {-attribute_id ""}
    {-attribute_name ""}
    {-object_type ""}
    {-format "text/plain"}
    -month
    -day
    -year
    -hour
    -minute
} {
    Save the value of an AMS timestamp attribute for an object.
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-07-22
    
    @param object_id The object for which the value is stored
    
    @param attribute_id The attribute_id of the attribute for which the value is retrieved
    
    @param attribute_name Alternatively the attribute_name for the attribute

    @param month Month of the object to store
    @param day Day of the object to store
    @param year Year of the object
    @param hour Hour of the object
    @param minute Minute of the object
    
    @return
    
    @error
} {
    if {[empty_string_p $attribute_id]} {
	set attribute_id [attribute::id \
			      -object_type "$object_type" -attribute_name "$attribute_name"]
    }
    if {[exists_and_not_null attribute_id]} {
	set value_id [ams::util::time_save -time "$month-$day-$year $hour:$minute"]
	ams::attribute::value_save -object_id $object_id -attribute_id $attribute_id -value_id $value_id
    }
}

ad_proc -public ams::attribute::save::postal_address {
    -object_id:required
    {-attribute_id ""}
    {-attribute_name ""}
    {-object_type ""}
    {-format "text/plain"}
    -delivery_address:required
    -municipality:required
    -region:required
    -postal_code:required
    -country_code:required
    {-additional_text ""}
    {-postal_type ""}
} {
    Save the value of an AMS timestamp attribute for an object.
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-07-22
    
    @param object_id The object for which the value is stored
    
    @param attribute_id The attribute_id of the attribute for which the value is retrieved
    
    @param attribute_name Alternatively the attribute_name for the attribute

    @param delivery_address Street Information
    @param municipality City/Town
    @param region Region
    @param postal_code Postal / ZIP Code
    @param country_code Country Code of the address
    @param additional_text Additional text for the address
    @param postal_type Addtional postal type information
    
    @return
    
    @error
} {
    if {[empty_string_p $attribute_id]} {
	set attribute_id [attribute::id \
			      -object_type "$object_type" -attribute_name "$attribute_name"]
    }
    if {[exists_and_not_null attribute_id]} {
	set value_id [ams::util::postal_address_save \
			  -delivery_address $delivery_address \
			  -municipality $municipality \
			  -region $region \
			  -postal_code $postal_code \
			  -country_code $country_code \
			  -additional_text $additional_text \
			  -postal_type $postal_type]
	ams::attribute::value_save -object_id $object_id -attribute_id $attribute_id -value_id $value_id
    }
}


ad_proc -public ams::attribute::save::simple_phone_number {
    -object_id:required
    {-attribute_id ""}
    {-attribute_name ""}
    {-object_type ""}
    -phone_number:required
} {
    Save the value of an AMS timestamp attribute for an object.
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-07-22
    
    @param object_id The object for which the value is stored
    
    @param attribute_id The attribute_id of the attribute for which the value is retrieved
    
    @param attribute_name Alternatively the attribute_name for the attribute

    @param phone_number  The simple phone number without any extras

    @return
    
    @error
} {

    if {[empty_string_p $attribute_id]} {
	set attribute_id [attribute::id \
			      -object_type "$object_type" -attribute_name "$attribute_name"]
    }
    if {[exists_and_not_null attribute_id]} {

	set value_id [ams::util::telecom_number_save -subscriber_number $phone_number]
	ams::attribute::value_save -object_id $object_id -attribute_id $attribute_id -value_id $value_id
    }
}


ad_proc -public ams::attribute::save::mc {
    -object_id:required
    {-attribute_id ""}
    {-attribute_name ""}
    {-object_type ""}
    -value
    {-format "text/plain"}
} {
    Save the value of an AMS multiple choice attribute like "select",
    "radio"  for an object.
    
    @author Malte Sussdorff (sussdorff@sussdorff.de)
    @creation-date 2005-07-22
    
    @param object_id The object for which the value is stored
    
    @param attribute_id The attribute_id of the attribute for which the value is retrieved
    
    @param attribute_name Alternatively the attribute_name for the attribute

    @return
    
    @error
} {
    if {[exists_and_not_null value]} {
	# map values if corresponding mapping-function
	# exists
	
	set proc "map_$attribute_name"
	
	if {[llength [info procs $proc]] == 1} {
	    if {[exists_and_not_null value]} {
		if {[catch {set value [eval $proc {$value}]} err]} {
		    append error_string "Contact \#$contact_count ($first_names $last_name): $err<br>"
		}
	    }
	}
    }
    
    if {[exists_and_not_null value]} {

	if {[empty_string_p $attribute_id]} {
	    set attribute_id [attribute::id \
				  -object_type "$object_type" -attribute_name "$attribute_name"]
	}

	switch $value {
	    "TRUE" {set value "t" }
	    "FALSE" {set value "f" }
	}
	set option_id [db_string get_option {select option_id from ams_option_types where attribute_id = :attribute_id and option = :value} \
			   -default {}]

	# Create the option if it no already existed.
	if {![exists_and_not_null option_id]} {
	    set option_id [ams::option::new \
			       -attribute_id $attribute_id \
			       -option $value]
	    ns_log notice "...... CREATED OPTION $option_id: $value"
	}
	
	# Save the value using the option_id
	set value_id [ams::util::options_save \
			  -options $option_id]
	ams::attribute::value_save -object_id $object_id -attribute_id $attribute_id -value_id $value_id
	ns_log Notice "AMS MC:: $object_id  - $attribute_id - $value_id"
    }
}
