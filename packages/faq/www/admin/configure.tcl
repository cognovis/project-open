ad_page_contract {

    This page allows a faq admin to change instance wide settings.

    @author Nima Mazloumi (nima.mazloumi@gmx.de)
    @creation-date  2004-08-11

} {
    {return_url ""}
}

set title "#faq.Configure#"
set context [list $title]

set use_categories_p [parameter::get -parameter "EnableCategoriesP"]
set use_wysiwyg_p [parameter::get -parameter "UseWysiwygP"]

ad_form -name categories_mode -form {
    {cat_enabled_p:text(radio)
        {label "#faq.Enable_Categories#"}
        {options {{[_ faq.Yes] 1} {[_ faq.No] 0}}}
	{value $use_categories_p}}
    {wysiwyg_enabled_p:text(radio)
	{label "#faq.Enable_WYSIWYG#"}
	{options {{[_ faq.Yes] t} {[_ faq.No] f}}}
	{value $use_wysiwyg_p}
    }
    {return_url:text(hidden) {value $return_url}}
    {submit:text(submit) {label "[_ faq.Change_settings]"}}
} -on_submit {
    parameter::set_value  -parameter "EnableCategoriesP" -value $cat_enabled_p
    parameter::set_value  -parameter "UseWysiwygP" -value $wysiwyg_enabled_p
    if {![empty_string_p $return_url]} {
        ad_returnredirect $return_url
    }
}
