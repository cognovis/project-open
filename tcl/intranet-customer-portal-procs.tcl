# /packages/intranet-core/tcl/intranet-profile-procs.tcl
#
# Copyright (C) 2011 ]project-open[
#
# This program is free software. You can redistribute it
# and/or modify it under the terms of the GNU General
# Public License as published by the Free Software Foundation;
# either version 2 of the License, or (at your option)
# any later version. This program is distributed in the
# hope that it will be useful, but WITHOUT ANY WARRANTY;
# without even the implied warranty of MERCHANTABILITY or
# FITNESS FOR A PARTICULAR PURPOSE.
# See the GNU General Public License for more details.

# Profiles represent OpenACS groups used by ]project-open[
# However, for performance reasons we have introduced special
# caching and auxillary functions specific to ]po[.

# @author klaus.hofeditz@project-open.com



ad_proc -public im_list_rfqs_component {} {
    Returns a component that list all current RFQ together with their status
    and action options, such as "Accept/Deny Quote". 
    
} {

    set user_id [ad_get_user_id]
    set html_output "<div id='gridRFQ'></div><br>"

    if { [im_profile::member_p -profile_id [im_customer_group_id] -user_id $user_id] } {
		append html_output "<button class='form-button40' id='getNewQuote' onclick=\"document.location.href='/intranet-customer-portal/upload-files'; return false;\">Get a new quote</button>"
    }
    if {[im_openacs54_p]} {
        # Include sencha libs
        template::head::add_css -href "/intranet-sencha/css/ext-all.css" -media "screen" -order 1
        template::head::add_javascript -src "/intranet-sencha/js/ext-all.js" -order 1
        # CSS Adjustemnts to ExtJS
        template::head::add_css -href "/intranet-customer-portal/intranet-customer-portal.css" -media "screen" -order 10
        # Include Component JS
        template::head::add_javascript -src "/intranet-customer-portal/resources/js/rfq-list.js" -order 200
    } else {
		append html_output "<script language='javascript'>"
		append html_output [ad_parse_template "/packages/intranet-customer-portal/www/resources/js/rfq-list.js"]
		append html_output "</script>"
    }

    return $html_output
}

ad_proc -public im_list_financial_documents_component {} {
    Returns a component that list all current RFQ together with their status
    and action options, such as "Accept/Deny Quote".

} {

    set user_id [ad_get_user_id]
    set html_output "<div id='gridFinancialDocuments'></div><br>"

    if {[im_openacs54_p]} {
	# Include sencha libs
	template::head::add_css -href "/intranet-sencha/css/ext-all.css" -media "screen" -order 1
	template::head::add_javascript -src "/intranet-sencha/js/ext-all.js" -order 1
	# CSS Adjustemnts to ExtJS
	template::head::add_css -href "/intranet-customer-portal/intranet-customer-portal.css" -media "screen" -order 10
	# Include Component JS
	template::head::add_javascript -src "/intranet-customer-portal/resources/js/financial-documents-list.js" -order 200
    } else {
	append html_output "<script language='javascript'>"
	append html_output [ad_parse_template "/packages/intranet-customer-portal/www/resources/js/financial-documents-list.js"]
	append html_output "</script>"
    }

    return $html_output
}


ad_proc im_trans_language_select_cp {
    {-translate_p 0}
    {-include_empty_p 1}
    {-include_empty_name "--_Please_select_--"}
    {-include_country_locale 0}
    {-locale ""}
    select_name
    { default "" }
} {
    set bind_vars [ns_set create]
    set category_type "Intranet Translation Language"
    ns_set put $bind_vars category_type $category_type

    set country_locale_sql ""
    if {!$include_country_locale} {
        set country_locale_sql "and length(category) < 5"
    }

    set sql "
        select *
        from
                (select
                        category_id,
                        category,
                        category_description
                from
                        im_categories
                where
                        (enabled_p = 't' OR enabled_p is NULL) and
                        category_type = :category_type
                        $country_locale_sql
                ) c
        order by lower(category)
    "

    return [im_selection_to_select_box_cp -translate_p $translate_p -locale $locale -include_empty_p $include_empty_p -include_empty_name $include_empty_name $bind_vars category_select $sql $select_name $default]
}


ad_proc im_selection_to_select_box_cp {
    {-translate_p 1}
    {-package_key "intranet-core" }
    {-locale "" }
    {-include_empty_p 1}
    {-include_empty_name "--_Please_select_--"}
    {-tag_attributes {} }
    {-size "" }
    bind_vars
    statement_name
    sql
    select_name
    { default "" }
} {
    Expects selection to have a column named id and another named name.
    Runs through the selection and return a select bar named select_name,
    defaulted to $default
    @param tag_attributes Key-value list of tag attributes.
           Value is to be enclosed by double quotes by the system.
} {
    array set tag_hash $tag_attributes
    set tag_hash(name) $select_name
    set tag_hash(id) $select_name
    if {"" != $size} { set tag_hash(size) $size }
    set tag_attribute_html ""
    foreach key [array names tag_hash] {
        set val $tag_hash($key)

        # Check for unquoted double quotes.
        if {[regexp {ttt} $val match]} { ad_return_complaint 1 "im_selection_to_select_box: found unquoted double quotes in tag_attributes" }

        append tag_attribute_html "$key=\"$val\" "
    }

    set result "<select $tag_attribute_html>\n"
    if {$include_empty_p} {

        if {"" != $include_empty_name} {
            set include_empty_name [lang::message::lookup $locale intranet-core.[lang::util::suggest_key $include_empty_name] $include_empty_name]
        }
        append result "<option value=\"\">$include_empty_name</option>\n"
    }
    append result [db_html_select_value_options_multiple \
                       -translate_p $translate_p \
                       -package_key $package_key \
                       -locale $locale \
                       -bind $bind_vars \
                       -select_option $default \
                       $statement_name \
                       $sql \
		       ]
    append result "\n</select>\n"
    return $result
}

