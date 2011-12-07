# /packages/intranet-customer-portal/www/upload-files.tcl
#
# Copyright (C) 2011 ]project-open[
# The code is based on ArsDigita ACS 3.4
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

ad_page_contract {
    @param 
    @author Klaus Hofeditz (klaus.hofeditz@project-open.com)
} {
    {security_token ""}
    {inquiry_id ""}
    {reset_p ""}
    {cancel_p ""}
}

# ---------------------------------------------------------------
# Security & Defaults
# ---------------------------------------------------------------

set page_title "Request for Quote"
set show_navbar_p 0
set show_left_navbar_p 0
set anonymous_p 1
set company_placeholder ""
set session_id [ad_get_signed_cookie "ad_session_id"]

if { "" != $security_token } {
    if { $inquiry_id == 0} {
	ad_return_complaint 1 "You have to register first in order to upload files. Please refer to our <a href='/intranet-customer-portal/'>Customer Portal</a>"
    }
    set master_file "../../intranet-customer-portal/www/master"
} else {
    set user_id [ad_maybe_redirect_for_registration]
    set anonymous_p 0
    set master_file "../../intranet-core/www/master"

    # refresh / double click should not create new inquiry 
    set inquiry_exists_p [db_string get_view_id "select inquiry_id from im_inquiries_customer_portal where session_id='$session_id' and inquiry_id=:inquiry_id and status_id = null" -default 0]

    # "reset" forces new inquiry
    if { 1==$reset_p } {set inquiry_exists_p 0}

    if { !$inquiry_exists_p } {
	set email [im_email_from_user_id $user_id]

	set ctr 0  
	set option_str ""
	set column_sql "
		select 
			a.object_id_one as company_id,  
			(select company_name from im_companies where company_id = a.object_id_one) as company_name 
		from 
			acs_rels a
		where 
			object_id_two = $user_id and 
			rel_type = 'im_company_employee_rel'
		limit 1
    	"
	# db_foreach col $column_sql 
	#	incr ctr
	#	# append option_str "<option value='$company_id'>$company_name</option>"
    	# 
    
	# if  1 < $ctr 
	#	append company_placeholder "We have registered you for at least companies. Please choose the one you inquire the quote for:"
	#	append company_placeholder "<select id=\"company_id\" name=\"company_id\""
	#	append company_placeholder $option_str
	#	append company_placeholder </select>
    	#  elseif  1 == $ctr 

        if { [catch {
	    db_1row get_company_data $column_sql
        } err_msg] } {
            ad_return_complaint 1 "We could not find a company for your account. Please get in touch with your 'Key Account Manager'"
        }

	db_1row get_company_data $column_sql 

	set company_placeholder "<span style='font-weight: bold'>Company:&nbsp;</span>"
	append company_placeholder "$company_name<br><br>"

	set inquiry_id [db_string nextval "select nextval('im_inquiries_customer_portal_seq');"]
	set str_length 40
	set security_token [subst [string repeat {[format %c [expr {int(rand() * 26) + (int(rand() * 10) > 5 ? 97 : 65)}]]} $str_length]]
	db_dml insert_inq "
        	insert into im_inquiries_customer_portal
                	(inquiry_id, user_id, email, security_token, company_id, session_id, inquiry_date)
	        values
        	        ($inquiry_id, $user_id, '$email', '$security_token', $company_id, '$session_id', now())
    	"

	# Create tmp path 
	set temp_path [parameter::get -package_id [apm_package_id_from_key intranet-customer-portal] -parameter "TempPath" -default "/tmp"]

	if { [catch {
	    file mkdir "$temp_path/$security_token"
	} err_msg] } {
            ad_return_complaint 1 "Could not create temp directory, please check if paramter 'TempPath' of package 'intranet-customer-portal' contains a valid path."
	}
    } else {
	db_1row inquiry_info "select inquiry_id, security_token from im_inquiries_customer_portal where session_id = '$session_id'"  
    }
}

if {[im_openacs54_p]} {

    # Load Sencha libs 
    template::head::add_css -href "/intranet-sencha/css/ext-all.css" -media "screen" -order 1
    template::head::add_javascript -src "/intranet-sencha/js/ext-all.js" -order 1

    # CSS Adjustemnts to ExtJS
    template::head::add_css -href "/intranet-customer-portal/intranet-customer-portal.css" -media "screen" -order 10

    # Load SuperSelectBox
    template::head::add_css -href "/intranet-customer-portal/resources/css/BoxSelect.css" -media "screen" -order 2
    template::head::add_javascript -src "/intranet-customer-portal/resources/js/BoxSelect.js" -order 100
}

# ---------------------------------------------------------------
# Set HTML elements
# ---------------------------------------------------------------

#Source Language 
set source_language_id 0
set include_source_language_country_locale [ad_parameter -package_id [im_package_translation_id] SourceLanguageWithCountryLocaleP "" 0]

set source_language_combo [im_trans_language_select_cp -include_country_locale $include_source_language_country_locale source_language_id $source_language_id ]
# set source_language_combo [im_trans_language_select -include_country_locale $include_source_language_country_locale]


#Target Language
# set target_language_ids [im_target_language_ids 0]
# set target_language_combo [im_category_select_multiple -translate_p 0 "Intranet Translation Language" target_language_ids $target_language_ids 12 multiple]

# Delivery Date 


# ---------------------------------------------------------------
# Add customer registration
# ---------------------------------------------------------------

if { "" == $reset_p } { set reset_p 0 }
if { "" == $cancel_p } { set cancel_p 0 }

if {[im_openacs54_p]} {
    template::head::add_javascript -src "/intranet-customer-portal/resources/js/upload-files-form.js?inquiry_id=$inquiry_id&security_token=$security_token" -order 2
    set js_include ""
} else {
    
    set params [list \
                    [list inquiry_id $inquiry_id] \
		    [list security_token $security_token] \
		    [list reset_p $reset_p] \
		    [list cancel_p $cancel_p] \
		    ]
    set js_include [ad_parse_template -params $params "/packages/intranet-customer-portal/www/resources/js/upload-files-form.js"]
}
