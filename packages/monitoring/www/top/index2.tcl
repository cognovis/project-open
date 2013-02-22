ad_page_contract {
    Displays df stats from top.

    @author        Roop <roop@teknedigital.com.br>
    
} {
  {orderby "top_id"}
  {page:optional}
  {mounted_id:optional}

}

set title "[_ monitoring.TOP]"
set context [list "$title"]

template::list::create -name top_itens \
                       -multirow top_itens \
		       -no_data "Sem dados no momento " \
		       -page_flush_p 1 \
		       -page_size 50 \
		       -page_query_name select_top_itens_paginator \
		       -actions [list "[_ monitoring.Delete]" "delete" "[_ monitoring.Delete]" \
		                      "[_ monitoring.Run]" "run" "[_ monitoring.Run]" \
				      "[_ monitoring.Save]" "save_top" "[_ monitoring.Save]"]\
		       -elements {
                           top_id              { label "[_ monitoring.top_id]" }
			   memory_real         { label "[_ monitoring.memory_real]" }
			   memory_free         { label "[_ monitoring.memory_free]" }
			   memory_swap_free    { label "[_ monitoring.memory_swap_free]" }
			   memory_swap_in_use  { label "[_ monitoring.memory_swap_in_use]" }
			   procs_total         { label "[_ monitoring.procs_total]" }
                           timestamp           { label "[_ monitoring.timestamp]" }
                           cpu_idle            { label "[_ monitoring.cpu_idle]" }
                           cpu_user            { label "[_ monitoring.cpu_user]" }    
                           cpu_kernel          { label "[_ monitoring.cpu_kernel]" }
			   display_top         {
				                 label "[_ monitoring.display_top]"
						 display_template { <a href="display_top?top_id=@top_itens.top_id@"> [_ monitoring.display_this_top] </a> } 
			}
                            
		 
    } -orderby {
        top_id {
            orderby "lower(top_id)"
        }
        memory_free {
            orderby "lower(memory_free)"
        }
        cpu_idle {
	    orderby "lower(cpu_idle)"
	}        
    }



                        #timestamp           { label "[_ monitoring.timestamp]" }
			#load_avg_1          { label "[_ monitoring.load_avg_1]" }
                        #load_avg_5          { label "[_ monitoring.load_avg_5]" }
                        #load_avg_15         { label "[_ monitoring.load_avg_15]" }
                        #procs_total         { label "[_ monitoring.procs_total]" }
                        #procs_sleeping      { label "[_ monitoring.procs_sleeping]" }
                        #procs_zombie        { label "[_ monitoring.procs_zombie]" }
                        #procs_stopped       { label "[_ monitoring.procs_stopped]" }
                        #procs_on_cpu        { label "[_ monitoring.procs_on_cpu]" }
                        #cpu_idle            { label "[_ monitoring.cpu_idle]" }


db_multirow   top_itens select_top_itens { 

} 

ad_return_template
