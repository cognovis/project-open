ad_page_contract {
	testing reports	
} {

}

set user_id [ad_maybe_redirect_for_registration]
set page_title "Invoices Report"
set context_bar [im_context_bar $page_title]
set context ""
set today [db_string today "select to_char(sysdate, 'YYYYMMDD.HHmm') from dual"]

# ------------------------------------------------------------
# Define the report - SQL, counters, headers and footers 
#

set sql "
    select
	ic.*,
	ii.*,
	coalesce(ic.paid_amount, 0) as paid_amount,
	to_char(ic.effective_date, 'YYYY-MM') as effective_month,
	to_char(ic.effective_date, 'YYYY-MM-DD') as effective_date_formatted,
	cust.company_name as customer_name,
	prov.company_name as provider_name
    from
	im_costs ic,
	im_invoices ii,
	im_companies cust,
	im_companies prov
    where
	ic.cost_id = ii.invoice_id
	and ic.customer_id = cust.company_id
	and ic.provider_id = prov.company_id
    order by
	to_char(ic.effective_date, 'YYYY-MM'),
	lower(cust.company_name)
"

set amount_counter [list \
	pretty_name Amount \
	var amount_subtotal \
	reset \$customer_id \
	expr \$amount
]

set paid_counter [list \
	pretty_name Paid \
	var paid_subtotal \
	reset \$customer_id \
	expr \$paid_amount
]

set counters [list \
	$amount_counter \
	$paid_counter \
]


set row {$effective_date_formatted $customer_name $provider_name "$amount $currency" "$paid_amount $paid_currency" "row"}

set content3 [list  \
    header $row  \
    group_by "" \
    content {} \
]

set header2 {"$effective_month" "$customer_name" "" "" "" "header2" }
set footer2 {"$effective_month" "" "" "\$amount_subtotal" "\$paid_subtotal" "footer2" }
set content2 [list  \
    header $header2 \
    footer $footer2 \
    group_by customer_name \
    content $content3
]

set header1 {"" "" "" "" "" "header1" }
set footer1 {"" "" "" "" "" "footer1" }
set report_def [list \
    header $header1 \
    footer $footer1 \
    group_by effective_month \
    content $content2 \
]

# Global header/footer
set header0 {"Date" "Customer" "Provider" "Amount" "Paid" "header0"}
set footer0 {"" "" "" "" "" "footer0"}


# ------------------------------------------------------------
# Start formatting the page
#

ad_return_top_of_page "
[im_header]
[im_navbar]
<H1>$page_title</H1>
<table border=0 cellspacing=1 cellpadding=1>\n"

im_report_render_row \
    -row $header0 \
    -row_class rowtitle \
    -field_class rowtitle

set footer_array_list [list]
set last_value_list [list]
db_foreach sql $sql {

    im_report_display_footer \
	-group_def $report_def \
        -footer_array_list $footer_array_list \
	-last_value_array_list $last_value_list

    im_report_update_counters -counters $counters

    set last_value_list [im_report_render_header \
	-group_def $report_def \
	-last_value_array_list $last_value_list \
    ]

    set footer_array_list [im_report_render_footer \
	-group_def $report_def \
	-last_value_array_list $last_value_list \
    ]

}

im_report_display_footer \
    -group_def $report_def \
    -footer_array_list $footer_array_list \
    -last_value_array_list $last_value_list \
    -display_all_footers_p 1

im_report_render_row \
    -row $footer0

ns_write "</table>\n[im_footer]\n"
