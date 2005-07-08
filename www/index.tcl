# /packages/intranet-exchange-rate/www/index.tcl
#
# Copyright (C) 2003-2004 Project/Open
#
# All rights reserved. Please check
# http://www.project-open.com/license/ for details.

ad_page_contract {
    @author Frank Bergmann frank.bergmann@project-open.com
    @creation-date 2005-06-04
    @cvs-id $Id$

} {
    {orderby "name"}
    {today ""}
}

# ---------------------------------------------------------------
# Default & Security
# ---------------------------------------------------------------

set page_title "Object Types"
set context [list $page_title]
set page_focus "im_header_form.keywords"

set user_id [ad_maybe_redirect_for_registration]
set user_is_admin_p [im_is_user_site_wide_or_intranet_admin $user_id]
if {!$user_is_admin_p} {
    ad_return_complaint 1 "You have insufficient privileges to use this page"
    return
}

if {"" == $today} {
    set today [lindex [split [ns_localsqltimestamp] " "] 0]
}

set form_id "exchange_rates"

# ------------------------------------------------------------------
# Build the form
# ------------------------------------------------------------------

set supported_currencies [db_list supported_currencies "
        select iso
        from currency_codes
        where supported_p = 't'
"]


list::create \
    -name $form_id \
    -multirow $form_id \
    -key day \
    -row_pretty_plural "Exchange Rates" \
    -checkbox_name checkbox \
    -selected_format "normal" \
    -class "list" \
    -main_class "list" \
    -sub_class "narrow" \
    -actions {
    } -bulk_actions {
    } -elements {
        day {
            display_col day
            label "Date"
            link_url_eval "new?today=$day"
        }
        eur_rate {
            display_col eur_rate
            label "EUR"
        }
    } -filters {
    } -groupby {
    } -orderby {
    } -formats {
        normal {
            label "Table"
            layout table
            row {
                day {}
                eur_rate {}
            }
        }
    }


db_multirow -extend { object_attributes_url } $form_id select_exchange_rates {
	select
		dates.day,
		(select	ier.rate
		 from	im_exchange_rates ier
		 where 
			ier.day = dates.day
			and currency = 'EUR'
		) as eur_rate
	from
		(select distinct
			day
			from im_exchange_rates
			where
				day >= to_date(to_char(to_date(:today, 'YYYY-MM-DD'), 'YYYY-MM'), 'YYYY-MM')
				and
				day <= to_date(to_char(to_date(:today, 'YYYY-MM-DD')+31, 'YYYY-MM'), 'YYYY-MM')
		) dates
	order by
		dates.day

} {
    set object_attributes_url ""
}


ad_return_template

