ad_page_contract {
} {
}

set title "[_ monitoring.DF]"
set context [list [list "index" "[_ monitoring.DF]" ] "[_ monitoring.Graph]"]

#select last df_log
 db_1row last_fd_log "select   df_id, 
                               to_char(timestamp,'DD/MM/YY HH24:MI') as timestamp
		      from     ad_monitoring_df 
		      order by df_id desc 
		      limit 1"    
		      
		      
#filter details from last log   
template::list::create -name df_itens \
                       -multirow df_itens \
		       -no_data "Sem dados no momento " \
		       -page_flush_p 1 \
		       -elements {
		           mounted             { label "[_ monitoring.mounted]" link_url_col detail_url}
                           filesystem           { label "[_ monitoring.filesystem]" }
			   size                { label "[_ monitoring.size]" }
			   used                { label "[_ monitoring.used]" }
			   avail               { label "[_ monitoring.avail]" }
			   used_percent        { label "[_ monitoring.used_percent]" }
			   
			} 
			
			
db_multirow -extend { detail_url } df_itens select_lines {
        select df_item_id,
	          filesystem,
	          size,
	          used,
	          avail,
	          used_percent,
	          mounted	   
	  from    ad_monitoring_top_df_item i,
                 ad_monitoring_df d
	  where i.df_id = d.df_id
	  and   d.df_id = :df_id
    } {
        set detail_url [export_vars -base "detail" { mounted }]
    }

    
# create diagram for last log    
db_multirow datasource select_objects "
     select mounted, 
            rtrim(used_percent, '%') as y
    from    ad_monitoring_top_df_item 
    where df_id = :df_id"

template::diagram::create -name disk_usage \
            -multirow datasource \
	    -title "Objects" \
	    -x_label "Porcentagem" -y_label "Partição" \
	    -left 0 -top 0  -right 100 -bottom 100 \
	    -scales "2 1" \
	    -template medidor \
	       -elements { 
	            mounted { color "ffffff" label "mounted" size 2 }  
		}


ad_return_template

