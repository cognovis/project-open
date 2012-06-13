ad_page_contract {
} {
    {width 100}
    {height 100}
    {size 2}
    {color "ff5533"}
    {csv ""}
    {template cockpit}
    {limit 1}
    {top 100}
    {left 100}
}

set query "select 
    y3 as x1, case when random()>0.3 then (-1*(random()*y3/10)+y3) else ((random()*y3/10)+y3) end as x2,
    y3 as x3, case when random()>0.3 then (-1*(random()*y3/10)+y3) else ((random()*y3/10)+y3) end as x4
    from diagram_dummy_logs
    order by random()
    limit $limit"


db_multirow datasource select_objects $query

template::diagram::create \
    -name dia1 \
    -multirow datasource \
    -title "System Monitoring" \
    -left $left -top $top -right $width -bottom $height \
    -template $template \
    -elements {
        d1 {
	    label "Monitor"
            color "\#ff5533"
            size $size
        }
        d2 {
	    label "CPU1"
            color "\#$color"
            size $size
        }
    }

if {[exists_and_not_null csv]} {
    template::diagram::write_output -name dia1
}
ad_return_template
