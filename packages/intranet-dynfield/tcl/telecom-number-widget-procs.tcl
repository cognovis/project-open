ad_library {

    Telecom_Number input widget and datatype for the OpenACS templating system.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-09-28
    @cvs-id $Id: telecom-number-widget-procs.tcl,v 1.1 2009/01/22 19:38:48 cvs Exp $

}

namespace eval template {}
namespace eval template::data {}
namespace eval template::data::transform {}
namespace eval template::data::validate {}
namespace eval template::util {}
namespace eval template::util::telecom_number {}
namespace eval template::widget {}

ad_proc -public template::util::telecom_number { command args } {
    Dispatch procedure for the telecom_number object
} {
    eval template::util::telecom_number::$command $args
}

ad_proc -public template::util::telecom_number::create {
    {itu_id {}}
    {national_number {}}
    {area_city_code {}}
    {subscriber_number {}}
    {extension {}}
    {sms_enabled_p {}}
    {best_contact_time {}}
    {location {}}
    {phone_type_id {}}
} {
    return [list $itu_id $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time]
}

ad_proc -public template::util::telecom_number::html_view {
    {itu_id {}}
    {national_number {}}
    {area_city_code {}}
    {subscriber_number {}}
    {extension {}}
    {sms_enabled_p {}}
    {best_contact_time {}}
    {location {}}
    {phone_type_id {}}
} {
    set telecom_number ""
    if { [parameter::get_from_package_key -parameter "ForceCountryCodeOneFormatting" -package_key "ams" -default "0"] } {
        if { $national_number != "1" } {
            set telecom_number "[_ ams.international_dial_code]${national_number}-"
        }
    } else {
        set telecom_number ${national_number}
        if { [exists_and_not_null telecom_number] } { append telecom_number "-" }
    }
    append telecom_number $area_city_code
    if { [exists_and_not_null telecom_number] } { append telecom_number "-" }
    append telecom_number "$subscriber_number"
    if { [exists_and_not_null extension] } { append telecom_number "&nbsp;x$extension" }
    set phone_url [parameter::get_from_package_key -parameter "PhoneURL" -package_key "ams" -default ""]
    if {[empty_string_p $phone_url]} {
	return $telecom_number
    } else {
	return "<a href=\"[eval set foo $phone_url]\">$telecom_number</a>"
    }
}

ad_proc -public template::util::telecom_number::acquire { type { value "" } } {
    Create a new telecom_number value with some predefined value
    Basically, create and set the telecom_number value
} {
  set telecom_number_list [template::util::telecom_number::create]
  return [template::util::telecom_number::set_property $type $telecom_number_list $value]
}

ad_proc -public template::util::telecom_number::formats {} {
    Returns a list of valid telecom_number formats
} {
# MGEDDERT NOTE: there needs to be a way to implement a way to portray telecom_numberes differently by country
    return { US CA DE }
}

ad_proc -public template::util::telecom_number::itu_codes {} {
    Returns the country list. Cached.
} {
    # This needs to be implemented if needed in the UI
    return [util_memoize [list template::util::telecom_number::country_options_not_cached]]
}

ad_proc -public template::util::telecom_number::itu_codes_not_cached {} {
    Returns the country list.
} {
    # This needs to be implemented if needed in the UI
    return 0
}

ad_proc -public template::data::validate::telecom_number { value_ref message_ref } {

    upvar 2 $message_ref message $value_ref telecom_number_list

    set itu_id                 [template::util::telecom_number::get_property itu_id $telecom_number_list]
    set national_number        [template::util::telecom_number::get_property national_number $telecom_number_list]
    set area_city_code         [template::util::telecom_number::get_property area_city_code $telecom_number_list]
    set subscriber_number      [template::util::telecom_number::get_property subscriber_number $telecom_number_list]
    set extension              [template::util::telecom_number::get_property extension $telecom_number_list]
    set sms_enabled_p          [template::util::telecom_number::get_property sms_enabled_p $telecom_number_list]
    set best_contact_time      [template::util::telecom_number::get_property best_contact_time $telecom_number_list]
    set location               [template::util::telecom_number::get_property location $telecom_number_list]
    set phone_type_id          [template::util::telecom_number::get_property phone_type_id $telecom_number_list]
    
    if { ![parameter::get_from_package_key -parameter "ForceCountryCodeOneFormatting" -package_key "ams" -default "0"] } {
        # the number is not required to be formatted in a country code one friendly way

        # we need to verify that the number does not contain invalid characters
        set telecom_number_temp "$itu_id$national_number$area_city_code$subscriber_number$extension$sms_enabled_p$best_contact_time"
        regsub -all " " $telecom_number_temp "" telecom_number_temp
        if { ![regexp {^([0-9]|x|-|\+|/|\)|\(){1,}$} $telecom_number_temp match telecom_number_temp] } {
	    set message [_ ams.lt_Telecom_numbers_must_only_contain]
        }
    } else {
        # we have a number in country code one that must follow certain formatting guidelines
        # the template::data::transform::telecom_number proc will have already seperated 
        # the entry from a single entry field into the appropriate values if its formatted 
        # correctly. This means that if values exist for area_city_code and national_number
        # the number was formatted correctly. If not we need to reply with a message that lets
        # users know how they are supposed to format numbers.
        
        if { ![exists_and_not_null area_city_code] || ![exists_and_not_null national_number] } {
            set message [_ ams.lt_Telecom_numbers_in_country_code]
        }
    }

    if { [exists_and_not_null message] } {
        return 0
    } else {
        return 1
    }
}
    

ad_proc -public template::data::transform::telecom_number { element_ref } {

    upvar $element_ref element
    set element_id $element(id)

    # if in the future somebody wants a widget with many individual fields this will be necessary
    set itu_id              [ns_queryget $element_id.itu_id]
    set national_number     [ns_queryget $element_id.national_number]
    set area_city_code      [ns_queryget $element_id.area_city_code]
    set subscriber_number   [ns_queryget $element_id.subscriber_number]
    set extension           [ns_queryget $element_id.extension]
    set sms_enabled_p       [ns_queryget $element_id.sms_enabled_p]
    set best_contact_time   [ns_queryget $element_id.best_contact_time]
    set location            [ns_queryget $element_id.location]
    set phone_type_id       [ns_queryget $element_id.phone_type_id]

    # we need to seperate out the returned value into individual elements for a single box entry widget
    set number              [string trim [ns_queryget $element_id.summary_number]]

    if { ![parameter::get_from_package_key -parameter "ForceCountryCodeOneFormatting" -package_key "ams" -default "0"] } {
        # we need to verify that the number is formatted correctly
        # if yes we seperate the number into various elements
        set subscriber_number $number
    } else {
        # we need to verify that the number is a valid format. 
        
        # if the number is formatted correctly these regexp statements will automatically
        # set the appropriate values for this string
        set in_country_p [regexp {^(\d{3})-(\d{3}-\d{4})(x\d{1,})??$} $number match area_city_code subscriber_number extension]
        if { [string is true $in_country_p] } {
            set national_number "1"
         }
        
        set out_of_country_p [regexp {^011-(\d{1,})-(\d{1,})-(\d[-|\d]{1,}\d)(x\d{1,})??$} $number match national_number area_city_code subscriber_number extension]

        if { [string is false $in_country_p] && [string is false $out_of_country_p] } {
            # The number is not in a valid format we pass on the 
            # subscriber number for validation errors.
            set subscriber_number $number
        } else {
            # if there was an extension we need to remove the "X" from it
            regsub -all {^x} $extension {} extension
        }
    }
    if { [empty_string_p $subscriber_number] } {
        # We need to return the empty list in order for form builder to think of it 
        # as a non-value in case of a required element.
        return [list]
    } else {
        return [list [list $itu_id $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time $location $phone_type_id]]
    }
}

ad_proc -public template::util::telecom_number::set_property { what telecom_number_list value } {
    Set a property of the telecom_number datatype. 

    @param what One of
    <ul>
    <li>itu_id
    <li>national_number
    <li>area_city_code
    <li>subscriber_number
    <li>extension
    <li>sms_enabled_p
    <li>best_contact_time
    <li>location
    <li>phone_type_id
    </ul>

    @param telecom_number_list the telecom_number list to modify
    @param value the new value

    @return the modified list
} {

    set itu_id                 [template::util::telecom_number::get_property itu_id $telecom_number_list]
    set national_number        [template::util::telecom_number::get_property national_number $telecom_number_list]
    set area_city_code         [template::util::telecom_number::get_property area_city_code $telecom_number_list]
    set subscriber_number      [template::util::telecom_number::get_property subscriber_number $telecom_number_list]
    set extension              [template::util::telecom_number::get_property extension $telecom_number_list]
    set sms_enabled_p          [template::util::telecom_number::get_property sms_enabled_p $telecom_number_list]
    set best_contact_time      [template::util::telecom_number::get_property best_contact_time $telecom_number_list]
    set location               [template::util::telecom_number::get_property location $telecom_number_list]
    set phone_type_id          [template::util::telecom_number::get_property phone_type_id $telecom_number_list]

    switch $what {
        itu_id {
            return [list $value  $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time $location $phone_type_id]
        }
        national_number {
            return [list $itu_id $value           $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time $location $phone_type_id]
        }
        area_city_code {
            return [list $itu_id $national_number $value          $subscriber_number $extension $sms_enabled_p $best_contact_time $location $phone_type_id]
        }
        subscriber_number {
            return [list $itu_id $national_number $area_city_code $value             $extension $sms_enabled_p $best_contact_time $location $phone_type_id]
        }
        extension {
            return [list $itu_id $national_number $area_city_code $subscriber_number $value     $sms_enabled_p $best_contact_time $location $phone_type_id]
        }
        sms_enabled_p {
            return [list $itu_id $national_number $area_city_code $subscriber_number $extension $value         $best_contact_time $location $phone_type_id]
        }
        best_contact_time {
            return [list $itu_id $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $value             $location $phone_type_id]
        }
        location {
            return [list $itu_id $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time $value    $phone_type_id]
        }
        phone_type_id {
            return [list $itu_id $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time $location $value]
        }
        default {
            error "Parameter supplied to util::telecom_number::set_property 'what' must be one of: 'itu_id', 'subscriber_number', 'national_number', 'area_city_code', 'extension', 'sms_enabled_p', 'best_contact_time', 'location', 'phone_type_id'. You specified: '$what'."
        }
    }
}

ad_proc -public template::util::telecom_number::get_property { what telecom_number_list } {
    
    Get a property of the telecom_number datatype. Valid properties are: 
    
    @param what the name of the property. Must be one of:
    <ul>
    <li>itu_id (synonyms street_telecom_number, street)
    <li>national_number (synonyms city, town)
    <li>area_city_code (synonyms state, province)
    <li>subscriber_number (synonyms zip_code, zip)
    <li>extension (synonym country)
    <li>addtional_text (this is not implemented in the default US widget)
    <li>best_contact_time (this is not implemented in the default US widget)
    <li>sms_enabled_p (this is not implemented in the default US widget)
    <li>location (this is not implemented in the default US widget)
    <li>phone_type_id (this is not implemented in the default US widget)
    <li>html_view - this returns an nice html formatted view of the telecom_number
    </ul>
    @param telecom_number_list a telecom_number datatype value, usually created with ad_form.
} {

    switch $what {
        itu_id {
            return [lindex $telecom_number_list 0]
        }
        national_number {
            return [lindex $telecom_number_list 1]
        }
        area_city_code {
            return [lindex $telecom_number_list 2]
        }
        subscriber_number {
            return [lindex $telecom_number_list 3]
        }
        extension {
            return [lindex $telecom_number_list 4]
        }
        sms_enabled_p {
            return [lindex $telecom_number_list 5]
        }
        best_contact_time {
            return [lindex $telecom_number_list 6]
        }
        location {
            return [lindex $telecom_number_list 7]
        }
        phone_type_id {
            return [lindex $telecom_number_list 8]
        }
        html_view {
            set itu_id                 [template::util::telecom_number::get_property itu_id $telecom_number_list]
            set subscriber_number      [template::util::telecom_number::get_property subscriber_number $telecom_number_list]
            set national_number        [template::util::telecom_number::get_property national_number $telecom_number_list]
            set area_city_code         [template::util::telecom_number::get_property area_city_code $telecom_number_list]
            set extension              [template::util::telecom_number::get_property extension $telecom_number_list]
            set sms_enabled_p          [template::util::telecom_number::get_property sms_enabled_p $telecom_number_list]
            set best_contact_time      [template::util::telecom_number::get_property best_contact_time $telecom_number_list]
            set location               [template::util::telecom_number::get_property location $telecom_number_list]
            set phone_type_id          [template::util::telecom_number::get_property phone_type_id $telecom_number_list]
            return [template::util::telecom_number::html_view $itu_id $national_number $area_city_code $subscriber_number $extension $sms_enabled_p $best_contact_time $location $phone_type_id]
        }
        default {
            error "Parameter supplied to util::telecom_number::get_property 'what' must be one of: 'itu_id', 'subscriber_number', 'national_number', 'area_city_code', 'extension', 'sms_enabled_p', 'best_contact_time', 'location', 'phone_type_id'. You specified: '$what'."
        }
        
    }
}

ad_proc -public template::widget::telecom_number { element_reference tag_attributes } {
    Implements the telecom_number widget.

} {

  upvar $element_reference element

#  if { [info exists element(html)] } {
#    array set attributes $element(html)
#  }

#  array set attributes $tag_attributes

  if { [info exists element(value)] } {
      set itu_id                 [template::util::telecom_number::get_property itu_id $element(value)]
      set national_number        [template::util::telecom_number::get_property national_number $element(value)]
      set area_city_code         [template::util::telecom_number::get_property area_city_code $element(value)]
      set subscriber_number      [template::util::telecom_number::get_property subscriber_number $element(value)]
      set extension              [template::util::telecom_number::get_property extension $element(value)]
      set sms_enabled_p          [template::util::telecom_number::get_property sms_enabled_p $element(value)]
      set best_contact_time      [template::util::telecom_number::get_property best_contact_time $element(value)]
      set location               [template::util::telecom_number::get_property location $element(value)]
      set phone_type_id          [template::util::telecom_number::get_property phone_type_id $element(value)]
  } else {
      set itu_id                 {}
      set subscriber_number      {}
      set national_number        {}
      set area_city_code         {}
      set extension              {}
      set sms_enabled_p          {}
      set best_contact_time      {}
      set location               {}
      set phone_type_id          {}
  }
  
  set output {}

  if { [string equal $element(mode) "edit"] } {
      
      

      set attributes(id) \"telecom_number__$element(form_id)__$element(id)\"
      set summary_number ""
      if { [exists_and_not_null national_number] } {
          if { $national_number != "1" } {
              append summary_number "011-$national_number"
          }
      }
      if { [exists_and_not_null area_city_code] } {
          if { [exists_and_not_null summary_number] } { append summary_number "-" }
          append summary_number $area_city_code
      }
      if { [exists_and_not_null subscriber_number] } {
          if { [exists_and_not_null summary_number] } { append summary_number "-" }
          append summary_number $subscriber_number
      }
      if { [exists_and_not_null extension] } {
          if { [exists_and_not_null summary_number] } { append summary_number "x" }
          append summary_number $extension
      }
#      set summary_number "$national_number\-$area_city_code\-$subscriber_number\x$extension"
      append output "<input type=\"text\" name=\"$element(id).summary_number\" value=\"[ad_quotehtml $summary_number]\" size=\"20\">"
          
  } else {
      # Display mode
      if { [info exists element(value)] } {
          append output "[template::util::telecom_number::get_property html_view $element(value)]"
          append output "<input type=\"hidden\" name=\"$element(id).itu_id\" value=\"[ad_quotehtml $itu_id]\">"
          append output "<input type=\"hidden\" name=\"$element(id).national_number\" value=\"[ad_quotehtml $national_number]\">"
          append output "<input type=\"hidden\" name=\"$element(id).area_city_code\" value=\"[ad_quotehtml $area_city_code]\">"
          append output "<input type=\"hidden\" name=\"$element(id).subscriber_number\" value=\"[ad_quotehtml $subscriber_number]\">"
          append output "<input type=\"hidden\" name=\"$element(id).extension\" value=\"[ad_quotehtml $extension]\">"
          append output "<input type=\"hidden\" name=\"$element(id).sms_enabled_p\" value=\"[ad_quotehtml $sms_enabled_p]\">"
          append output "<input type=\"hidden\" name=\"$element(id).best_contact_time\" value=\"[ad_quotehtml $best_contact_time]\">"
          append output "<input type=\"hidden\" name=\"$element(id).location\" value=\"[ad_quotehtml $location]\">"
          append output "<input type=\"hidden\" name=\"$element(id).phone_type_id\" value=\"[ad_quotehtml $phone_type_id]\">"
      }
  }
      
  return $output
}
