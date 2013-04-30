ad_page_contract {
} {

    {d1 1}
    {d2 2}
    {width 480}
    {height 150}
    {dot_type 1}
    {type 1}
    {size 2}
    {d1_color "ff5533"}
    {d2_color "aaee33"}
    {csv ""}
    {x_scale 2}
    {y_scale 1}
    {template curve}
    {limit 200}
    {top 40}
    {left 100}
}

set title "[_ monitoring.Detail] "
set context [list [list "index" "[_ monitoring.DB]" ] [list "graph" "[_ monitoring.Graph]" ] "$title"]

set total [db_string count_fd_log "select count(db_id) from ad_monitoring_db"]

set content_frequency [ad_parameter -package_id [monitoring_pkg_id] DbFrequency monitoring 0]


set end_db_id [db_string end_id "select max(db_id) from ad_monitoring_db"]

set size_content_current [expr [db_string size_current "select size_content_repository from ad_monitoring_db where db_id = :end_db_id "] / 1024 ]

set size_content_current_kb [ad_monitor_format_kb $size_content_current]


set start [expr $total - $limit]
if { $start <=0} {
    set start 0
}
set end   [expr $start + $limit]
if { $end >= $total} {
    set end $total
}

db_multirow datasource select_objects "
select to_char(d.timestamp, 'YYYY,MM,DD,HH24,MI,SS') as x1,
       size_content_repository
from   ad_monitoring_db d
order by timestamp
limit $limit offset $start
"



template::diagram::create \
    -name content_repository_size \
    -multirow datasource \
    -title "Content Repository Size" \
    -x_label "Data" \
    -y_label "%" \
    -left $left -top $top -right $width -bottom $height \
    -scales "$x_scale $y_scale" \
    -template $template \
    -elements {
	d1 {
	    color "#$d1_color"
	    type 4
	    label "[_ monitoring.size_in_kb]"
	    size 2
	    dot_type 3
	    
	}
      
}

ad_return_template

