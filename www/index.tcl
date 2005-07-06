# /packages/intranet-exchange-rate/www/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract {
    Demo page to show indicators
    @author Frank Bergmann (frank.bergmann@project-open.com)
} {
    { form_mode "edit" }
}


# ---------------------------------------------------------------
# Defaults & Security
# ---------------------------------------------------------------

set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-exchange-rate.Exchange-Rate]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"
set return_url [im_url_with_query]

set form_id "exchange_rates"
set action_url "index"

set todays_date [lindex [split [ns_localsqltimestamp] " "] 0]

# ---------------------------------------------------------------
# Indicators
# ---------------------------------------------------------------

set supported_currencies [db_list supported_currencies "select iso from currency_codes where supported_p = 't'"]

ad_return_coplaint 1 $supported_currencies

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {return_url} \
    -form {
        {todays_date:date(text)
	    {label "[_ intranet-exchange-rate.Todays_Date]"} 
	}
}


template::element create $form_id $form_id \
    -datatype integer \
    -widget hidden \
    -value  $object_id

