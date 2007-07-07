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


db_multirow mydata select_objects {
    select
	to_char(x1, 'YYYY,MM,DD,HH24,MI,SS') as x1,
	y1
    from diagram_dummy_logs
}

template::diagram::create \
    -name dia1 \
    -multirow mydata \
    -title "My Diagram" \
    -x_label "X-Time" \
    -y_label "Y-Count" \
    -left $left -top $top -right $width -bottom $height \
    -scales "$x_scale $y_scale" \
    -template $template \
    -elements {
	mycurve {
	    color "#$d1_color"
	    type 1
	    label "My Curve"
	    size 5
	    dot_type 1
	}
    } 

ad_return_template