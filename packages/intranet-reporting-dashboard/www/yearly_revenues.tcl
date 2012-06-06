ad_page_contract {
} {
    {d1 1}
    {d2 2}
    {width 480}
    {height 150}
    {dot_type 1}
    {size 2}
    {d1_color "ff5533"}
    {d2_color "aaee33"}
    {csv ""}
    {x_scale 2}
    {y_scale 1}
    {template curve}
    {limit 20}
    {top 40}
    {left 100}
}

set query "select  
    to_char(x1, 'YYYY,MM,DD,HH24,MI,SS') as x1, 
    y1,
    to_char(x2, 'YYYY,MM,DD,HH24,MI,SS') as x2, 
    y2,
    to_char(x3, 'YYYY,MM,DD,HH24,MI,SS') as x3,
    y3
    from diagram_dummy_logs
    order by x1
    limit $limit"


db_multirow datasource select_objects $query


template::diagram::create \
    -name dia1 \
    -multirow datasource \
    -title "Monitoring - Dummy" \
    -x_label "Time" \
    -y_label "Count" \
    -left $left -top $top -right $width -bottom $height \
    -scales "$x_scale $y_scale" \
    -template $template \
    -elements {
	d1 {
	    color "#$d1_color"
	    type 1
	    label "Objects"
	    size 7
	    dot_type 3
	}
	d2 {
	    color "#$d2_color"
	    type 4
	    label "Memory"
	    size 1
	    dot_type 3
	}
	d3 {
	    color "#c0c0c0"
	    type 3
	    label "Disc Usage"
	    size 4
	    dot_type 4
	}
    } 

if {[exists_and_not_null csv]} {
    template::diagram::write_output -name dia1
}

ad_return_template