ad_library {

    Address input widget and datatype for the OpenACS templating system.

    @author Matthew Geddert openacs@geddert.com
    @creation-date 2004-09-28
    @cvs-id $Id: recurrence-widget-procs.tcl,v 1.1 2009/01/22 19:38:47 cvs Exp $

}

namespace eval template {}
namespace eval template::data {}
namespace eval template::data::transform {}
namespace eval template::data::validate {}
namespace eval template::util {}
namespace eval template::util::recurrence {}
namespace eval template::widget {}

ad_proc -public template::util::recurrence { command args } {
    Dispatch procedure for the recurrence object
} {
    eval template::util::recurrence::$command $args
}

ad_proc -public template::util::recurrence::create {
    {every_n {}}
    {interval_type {}}
    {days_of_week {}}
    {recur_until {}}
} {
    return [list $every_n $interval_type $days_of_week $recur_until]
}

ad_proc -public template::util::recurrence::html_view {
    {every_n {}}
    {interval_type {}}
    {days_of_week {}}
    {recur_until {}}
} {
    set recurrence "Every $every_n $interval_type"
    if { [exists_and_not_null days_of_week] } {
	append recurrence $days_of_week
    }
    if { [exists_and_not_null recur_until] } {
	append recurrence $recur_until
    }
    return [ad_text_to_html $recurrence]
}

ad_proc -public template::util::recurrence::acquire { type { value "" } } {
    Create a new recurrence value with some predefined value
    Basically, create and set the recurrence value
} {
  set recurrence_list [template::util::recurrence::create]
  return [template::util::recurrence::set_property $type $recurrence_list $value]
}


ad_proc -public template::data::validate::recurrence { value_ref message_ref } {

    upvar 2 $message_ref message $value_ref recurrence_list

    set delivery_recurrence [template::util::recurrence::get_property delivery_recurrence $recurrence_list]
    set municipality     [template::util::recurrence::get_property municipality $recurrence_list]
    set region           [template::util::recurrence::get_property region $recurrence_list]
    set postal_code      [template::util::recurrence::get_property postal_code $recurrence_list]
    set country_code     [template::util::recurrence::get_property country_code $recurrence_list]
    set additional_text  [template::util::recurrence::get_property additional_text $recurrence_list]
    set postal_type      [template::util::recurrence::get_property postal_type $recurrence_list]

    set message ""
    # this is used to make sure there are no invalid characters in the recurrence
    set recurrence_temp "$delivery_recurrence $municipality $region $postal_code $country_code $additional_text $postal_type"
    if { [::string match "\{" $recurrence_temp] || [::string match "\}" $recurrence_temp] } {
        # for built in display purposes these characters are not allowed, if you need it 
        # to be allowed make SURE that retrieval procs in AMS are also updated
        # to deal with this change
        if { [exists_and_not_null message_temp] } { append message " " }
        append message "[_ ams.Your_entry_must_not_contain_the_following_characters]: \{ \}."
    }
    if { $country_code == "US" } {
        # this should check a cached list
        # this proc cannot for some reason go in the postgresql file...
        if { ![db_0or1row validate_state {
        select 1 from us_states where abbrev = upper(:region) or state_name = upper(:region)
} ] } {
            if { [exists_and_not_null message_temp] } { append message " " }
            append message "\"$region\" [_ ams.is_not_a_valid_US_state]."
        }
    }
    if { [exists_and_not_null message_temp] } {
        return 0
    } else {
        return 1
    }
}
    

ad_proc -public template::data::transform::recurrence { element_ref } {

    upvar $element_ref element
    set element_id $element(id)

    set every_n          [ns_queryget $element_id.delivery_recurrence]
    set interval_type    [ns_queryget $element_id.municipality]
    set days_of_week     [ns_queryget $element_id.region]
    set recur_until      [ns_queryget $element_id.postal_code]

    if { [empty_string_p $every_n] } {
        # We need to return the empty list in order for form builder to think of it 
        # as a non-value in case of a required element.
        return [list]
    } else {
        return [list [list $every_n $interval_type $days_of_week $recur_until]]
    }
}

ad_proc -public template::util::recurrence::set_property { what recurrence_list value } {
    Set a property of the recurrence datatype. 

    @param what One of
    <ul>
    <li>every_n
    <li>interval_type
    <li>days_of_week
    <li>recur_until
    </ul>

    @param recurrence_list the recurrence list to modify
    @param value the new value

    @return the modified list
} {

    set every_n          [template::util::recurrence::get_property every_n $recurrence_list]
    set interval_type    [template::util::recurrence::get_property interval_type $recurrence_list]
    set days_of_week     [template::util::recurrence::get_property days_of_week $recurrence_list]
    set recur_until      [template::util::recurrence::get_property recur_until $recurrence_list]

    switch $what {
        every_n {
            return [list $value   $interval_type $days_of_week $recur_until]
        }
        interval_type {
            return [list $every_n $value         $days_of_week $recur_until]
        }
        days_of_week {
            return [list $every_n $interval_type $value        $recur_until]
        }
        recur_until {
            return [list $every_n $interval_type $days_of_week $value      ]
        }
        default {
            error "Parameter supplied to util::recurrence::set_property 'what' must be one of: 'every_n', 'interval_type', 'days_of_week', 'recur_until', 'html_view'. You specified: '$what'."
        }
    }
}

ad_proc -public template::util::recurrence::get_property { what recurrence_list } {
    
    Get a property of the recurrence datatype. Valid properties are: 
    
    @param what the name of the property. Must be one of:
    <ul>
    <li>every_n
    <li>interval_type
    <li>days_of_week
    <li>recur_until
    <li>html_view - this returns an nice html formatted view of the recurrence
    </ul>
    @param recurrence_list a recurrence datatype value, usually created with ad_form.
} {

    switch $what {
        every_n {
            return [lindex $recurrence_list 0]
        }
        interval_type {
            return [lindex $recurrence_list 1]
        }
        days_of_week {
            return [lindex $recurrence_list 2]
        }
        recur_until {
            return [lindex $recurrence_list 3]
        }
        html_view {
            set every_n          [template::util::recurrence::get_property every_n $recurrence_list]
            set interval_type    [template::util::recurrence::get_property interval_type $recurrence_list]
            set days_of_week     [template::util::recurrence::get_property days_of_week $recurrence_list]
            set recur_until      [template::util::recurrence::get_property recur_until $recurrence_list]
            return [template::util::recurrence::html_view $every_n $interval_type $days_of_week $recur_until]
        }
        default {
            error "Parameter supplied to util::recurrence::get_property 'what' must be one of: 'every_n', 'interval_type', 'days_of_week', 'recur_until', 'html_view'. You specified: '$what'."
        }
        
    }
}

ad_proc -public template::widget::recurrence { element_reference tag_attributes } {
    Implements the recurrence widget.

} {

  upvar $element_reference element

  if { [info exists element(value)] } {
      set every_n          [template::util::recurrence::get_property delivery_recurrence $element(value)]
      set interval_type    [template::util::recurrence::get_property postal_code $element(value)]
      set days_of_week     [template::util::recurrence::get_property municipality $element(value)]
      set recur_until      [template::util::recurrence::get_property region $element(value)]
  } else {
      set every_n          {}
      set interval_type    {}
      set days_of_week     {}
      set recur_until      {}
  }
  
  set output {}

  if { [string equal $element(mode) "edit"] } {

      set every_n_options {
	  {"Every" 1}
	  {"Every Other" 2}
	  {"Every Third" 3}
	  {"Every Forth" 4}
      }

      set interval_type_options {
	  {"Day" day}
	  {"Week" week}
	  {"Month on this Date" month_by_date}
	  {"Month on this Day" month_by_day}
	  {"Year" year}
      }

      set menuattributes(id) \"recurrence__$element(form_id)__$element(id)\"
      set dateattributes [list "name" "$element(id).recur_until"]

      append output "
<table cellpadding=\"0\" cellspacing=\"0\" border=\"0\">
  <tr>
    <td colspan=\"3\">Repeat [menu $element(id).every_n $every_n_options $every_n menuattributes] [menu $element(id).interval_type $interval_type_options $interval_type menuattributes]</td>
  </tr>
  <tr>
    <td colspan=\"3\">Until [text $element(id).recur_until $dateattributes]</td>
  </tr>
</table>
"
          
  } else {
      # Display mode
      if { [info exists element(value)] } {
          append output [template::util::recurrence::get_property html_view $element(value)]
          append output "<input type=\"hidden\" name=\"$element(id).every_n\" value=\"[ad_quotehtml $every_n]\">"
          append output "<input type=\"hidden\" name=\"$element(id).interval_type\" value=\"[ad_quotehtml $interval_type]\">"
          append output "<input type=\"hidden\" name=\"$element(id).days_of_week\" value=\"[ad_quotehtml $days_of_week]\">"
          append output "<input type=\"hidden\" name=\"$element(id).recur_until\" value=\"[ad_quotehtml $recur_until]\">"
      }
  }
      
  return $output
}
