
set page_title [lang::message::lookup "" intranet-reporting-indicators.Indicator "Indicator"]
set context $page_title

set indicator_sql "
	select
		result_date,
		result
	from 
		im_indicator_results
	where 
		result_indicator_id = 90449
	order by
		result_date
"

set values [db_list_of_lists results $indicator_sql]




set hist_values {
    { 0 5 }
    { 20 15 }
    { 40 50 }
    { 60 20 }
    { 80 10 }
}

set hist_values {
    { 0 5 }
    { 25 15 }
    { 50 50 }
    { 75 20 }
}




set histogram_html [im_indicator_timeline_widget -name "Test" -values $values -histogram_values $hist_values]

