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
    {limit 500}
    {top 40}
    {left 100}
    {pid}
    {command}
    {top_id ""}
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
       p.cpu_pct
from   ad_monitoring_top t,
       ad_monitoring_top_proc p
where p.pid = '$pid' and p.top_id = t.top_id
order by timestamp
limit $limit offset $start
"


template::diagram::create \
    -name disk_detail \
    -multirow datasource \
    -title "Porcentagem Usada" \
    -x_label "Data" \
    -y_label "%" \
    -left $left -top $top -right $width -bottom $height \
    -scales "$x_scale $y_scale" \
    -template $template \
    -elements {
	d1 {
	    color "#$d1_color"
	    type 4
	    label "Porcentagem Usada"
	    size 2
	    dot_type 3
	    
	}
      
}

if { [string equal $top_id ""] } {
   set return_url index
} else {
   set return_url "display_top?top_id=$top_id"
} 

ad_return_template

