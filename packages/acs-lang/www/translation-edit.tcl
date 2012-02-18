ad_page_contract {

    Edit i18n tranlations
    @author iuri sampaio (iuri.sampaio@gmail.com)
    @date 2010-09-21
} {
    locale
    return_url
}
   


if { [string length $locale] == 2 } {

    # Only language provided, let's get the default locale for this language                                                                                 
    set default_locale [lang::util::default_locale_from_lang $locale]
    if { $default_locale eq "" } {
        error "Could not look up locale for language $locale"
    } else {
        set locale $default_locale
    }
}

# We rename to avoid conflict in queries                                                                                                                   
set current_locale $locale
set default_locale en_US

set locale_label [lang::util::get_label $current_locale]
set default_locale_label [lang::util::get_label $default_locale]



# Get the form
set myform [ns_getform]
if {[string equal "" $myform]} {
    error "No Form was submited"
} else {

    # extract form fields using [ns_set] over a loop. The last three fields are locale, return_url and submit.
    for {set i 0} {$i < [expr [ns_set size $myform] - 3]} {incr i} {
	set varname [ns_set key $myform $i]
	set varvalue [ns_set value $myform $i]

	#split varname to package_key and message_key. The separator is + . Need to check if the varname has HTML tags!!
	set varname [split $varname "+"]
     
	set package_key [lindex $varname 0]
	set message_key [lindex $varname 1]
	set comment ""

	# Register message via acs-lang 
	if {$varvalue ne ""} {
	    lang::message::register -comment $comment $locale $package_key $message_key $varvalue
	}
    }
}

ad_returnredirect $return_url
ad_script_abort
