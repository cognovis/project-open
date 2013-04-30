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
    {limit 16}
    {top 40}
    {left 100}
}

set title "[_ monitoring.Detail] "
set context [list [list "index" "[_ monitoring.DF]" ] [list "graph" "[_ monitoring.Graph]" ] "$title"]


set df_frequency [ad_parameter -package_id [monitoring_pkg_id] DfFrequency monitoring 0]



set total [db_string count_fd_log "select count(top_id) from ad_monitoring_top"]

set start [expr $total - $limit]
if { $start <=0} {
    set start 0
}
set end   [expr $start + $limit]
if { $end >= $total} {
    set end $total
}

db_multirow datasource select_objects "
select to_char(t.timestamp, 'YYYY,MM,DD,HH24,MI,SS') as x1,
       memory_free
from   ad_monitoring_top t
order by timestamp
limit $limit offset $start
" 


template::diagram::create \
    -name disk_detail \
    -multirow datasource \
    -title "[_ monitoring.free_memory]" \
    -x_label "Data" \
    -y_label "%" \
    -left $left -top $top -right $width -bottom $height \
    -scales "$x_scale $y_scale" \
    -template $template \
    -elements {
	d1 {
	    color "#$d1_color"
	    type 4
	    label "[_ monitoring.free_memory_kbytes]"
	    size 1
	    dot_type 3
	    
	}
}

ad_return_template

