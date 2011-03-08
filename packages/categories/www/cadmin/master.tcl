#
# author: Timo Hentschel (timo@timohentschel.de)
#

if { ![info exists change_locale] } {
    set change_locale t
}

if {![exists_and_not_null locale]} {
    #set locale [parameter::get -parameter DefaultLocale -default en_US]
    set locale [ad_conn locale]
}

set languages [lang::system::get_locale_options]
set vars_to_export_list {tree_id category_id }

set set_id [ad_conn form]
set varname_list [ad_ns_set_keys -exclude {
  tree_id category_id locale form:mode form:id 
  __confirmed_p __refreshing_p formbutton:ok
  __submit_button_name __submit_button_value
} $set_id]

foreach name $varname_list {
  set $name [ns_set get $set_id $name]
  lappend vars_to_export_list $name
}

ad_form -name locale_form -action [ad_conn url] \
    -export $vars_to_export_list \
    -form {
      {locale:text(select),optional {label "Language"} {value $locale} {options $languages}}
    }
