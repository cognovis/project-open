ad_page_contract {
} {
    {d1 1}
    {d2 2}
    {width 80}
    {height 80}
    {dot_type 1}
    {size 2}
    {d1_color "ff5533"}
    {d2_color "aaee33"}
    {csv ""}
    {x_scale 2}
    {y_scale 1}
    {template pie}
    {limit 2}
    {top 0}
    {left 0}
}

set query "select  
    to_char(x1, 'HH24:MI:SS') as x1,
    y1
    from diagram_dummy_logs
    order by x1
    limit $limit"


db_multirow datasource select_objects $query

template::diagram::create \
    -name dia1 \
    -multirow datasource \
    -title "Objects" \
    -x_label "Time" \
    -y_label "Count" \
    -left $left -top $top -right $width -bottom $height \
    -scales "$x_scale $y_scale" \
    -template $template \
    -elements {
	d1 {
	    color "#$d1_color"
	    label "Pie 1"
	    size $size
	}
    }

if {[exists_and_not_null csv]} {
    template::diagram::write_output -name dia1
}
ad_return_template