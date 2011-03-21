#expects: view

if {![exists_and_not_null base_url]} {
    set base_url [ad_conn url]
}

if {![exists_and_not_null date]} {
    set date [dt_sysdate]
}

if {[exists_and_not_null page_num]} {
    set page_num "&page_num=$page_num"
} else {
    set page_num ""
}

if {![exists_and_not_null period_days] || [string equal $period_days [parameter::get -parameter ListView_DefaultPeriodDays -default 31]]} {
    set url_stub_period_days ""
} else {
    set url_stub_period_days "&period_days=${period_days}"
}

foreach test_view {list day week month calendar} {
    if { [string equal $test_view $view] } {
        set ${test_view}_selected_p t
    } else {
        set ${test_view}_selected_p f
    }
}

if { [string match /dotlrn* $base_url] } {
    set link "[export_vars -url -base $base_url -entire_form -exclude {export}]&export=print"
} else {
    set link "[export_vars -base $base_url {date {view day}}]&export=print"
}

multirow create views name text url spacer selected_p onclick

multirow append views \
    [_ calendar.Day] \
    "day" \
    "[export_vars -base $base_url {date {view day}}]${page_num}\#calendar" \
    "&nbsp;&nbsp; | &nbsp;&nbsp;" \
    $day_selected_p \
    ""

multirow append views \
    [_ calendar.Week] \
    "week" \
    "[export_vars -base $base_url {date {view week}}]${page_num}\#calendar" \
    "&nbsp;&nbsp; | &nbsp;&nbsp;" \
    $week_selected_p \
    ""

multirow append views \
    [_ calendar.Month] \
    "month" \
    "[export_vars -base $base_url {date {view month}}]${page_num}\#calendar" \
    "&nbsp;&nbsp; | &nbsp;&nbsp;&nbsp;&nbsp;&nbsp;" \
    $month_selected_p \
    ""

multirow append views \
    [_ calendar.List] \
    "list" \
    "[export_vars -base $base_url {date {view list}}]${page_num}${url_stub_period_days}\#calendar" \
    "" \
    $list_selected_p \
    ""

