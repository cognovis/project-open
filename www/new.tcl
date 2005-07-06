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
    { today "" }
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

if {"" == $today} {
    set today [lindex [split [ns_localsqltimestamp] " "] 0]
}

# ---------------------------------------------------------------
# Indicators
# ---------------------------------------------------------------

set supported_currencies [db_list supported_currencies "
	select iso 
	from currency_codes 
	where supported_p = 't'
"]

# ad_return_complaint 1 $supported_currencies

ad_form \
    -name $form_id \
    -cancel_url $return_url \
    -action $action_url \
    -mode $form_mode \
    -export {return_url} \
    -form {
        {today:text(text)
	    {label "Date"} 
	    {html {size 10}}
	}
}

foreach currency $supported_currencies {
    template::element create $form_id "${currency}_rate" \
	-datatype text \
	-widget text \
	-label $currency \
	-html {size 10}
}

ad_form -extend -name $form_id -on_request {
    # Populate elements from local variables

    template::element::set_value $form_id today $today

    foreach currency $supported_currencies {
	template::element::set_value $form_id "${currency}_rate" [db_string rate "
		select	rate
		from	im_exchange_rates
		where	currency = :currency
			and day = to_date(:today, 'YYYY-MM-DD')

	"]
    }
}  -after_submit {

    foreach currency $supported_currencies {
	set rate_name "${currency}_rate"

	db_dml update_rates "
		update im_exchange_rates
		set rate = :$rate_name
		where
			day = to_date(:today, 'YYYY-MM-DD')
			and currency = :currency

        "
    }
}


