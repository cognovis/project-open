#
# author: Timo Hentschel (timo@timohentschel.de)
#

if { ![info exists change_locale] } {
    set change_locale t
}

if {![exists_and_not_null locale]} {
    set locale [ad_parameter DefaultLocale acs-lang "en_US"]
    set locale [ad_conn locale]
}

set languages [lang::system::get_locale_options]

ad_form -name locale_form -action [ad_conn url] -export { tree_id category_id } -form {
    {locale:text(select) {label "Language"} {value $locale} {options $languages}}
}

set form_vars [export_ns_set_vars form {locale form:mode form:id __confirmed_p __refreshing_p formbutton:ok} [ad_conn form]]
