# /www/admin/monitoring/index.tcl

ad_page_contract {
    Displays df stats from disk partitions.

    @author        Roop <roop@teknedigital.com.br>
    
} {
  {orderby "timestamp"}
  {page:optional}
  {mounted_id:optional}

}

set title "[_ monitoring.DF]"
set context [list "$title"]


set lista_mounted [list]
db_foreach select_lista_mounted {} {
    lappend lista_mounted [list $mounted $mounted [lc_numeric $num_itens]]
}


if [exists_and_not_null mounted_id] {
    set mounted_where_clause "mounted = :mounted_id"
} else {
    set mounted_where_clause ""
}


template::list::create -name df_itens \
                       -multirow df_itens \
		       -no_data "Sem dados no momento " \
		       -page_query_name df_itens_pagination \
		       -page_size 50 \
		       -page_flush_p 1 \
		       -actions [list "[_ monitoring.Run_Now]" "df" "Run Now" "[_ monitoring.Delete]" "delete" "Delete" "[_ monitoring.Graph]" "graph" "Graph"]\
		       -elements {
                        timestamp           { label "[_ monitoring.timestamp]" }
		          filesystem          { label "[_ monitoring.filesystem]" }
			   size                { label "[_ monitoring.size]" }
			   used                { label "[_ monitoring.used]" }
			   avail               { label "[_ monitoring.avail]" }
			   used_percent        { label "[_ monitoring.used_percent]" }
			   mounted             { label "[_ monitoring.mounted]" }
			  
                            
			} -orderby {
                         timestamp           { label "[_ monitoring.timestamp]" orderby timestamp}
			    filesystem          { label "[_ monitoring.filesystem]" orderby filesystem}
			    size                { label "[_ monitoring.size]" orderby size}
			    used                { label "[_ monitoring.used]" orderby used}
			    avail               { label "[_ monitoring.avail]" orderby avail}
			    used_percent        { label "[_ monitoring.used_percent]" orderby used_percent}
			    mounted             { label "[_ monitoring.mounted]" orderby mounted}			   
  
			} -filters {
			   mounted_id {
                               label "[_ monitoring.mounted]"
                               values $lista_mounted
			           default_value ""
                               where_clause {
                                  $mounted_where_clause
                               }
                                  has_default_p f
                               }

			}

			

db_multirow   df_itens select_df_itens {

} 
ad_return_template






