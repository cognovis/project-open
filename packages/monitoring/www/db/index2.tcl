# /www/admin/monitoring/db/index2.tcl

ad_page_contract {
    Displays df stats from db size.

    @author        Alessandro Landim <alessandro.landim@teknedigital.com.br>
    
} {
  {orderby "timestamp"}
  {page:optional}
}

set title "[_ monitoring.DB]"
set context [list "$title"]

template::list::create -name db_size_itens \
                       -multirow db_size_itens \
		       -no_data "Sem dados no momento " \
		       -page_flush_p 1 \
		       -actions [list "[_ monitoring.Delete]" "delete" "[_ monitoring.Delete]" \
				      "[_ monitoring.Save]" "save_db_size" "[_ monitoring.Save]"] \
		       -elements {
                           db_id              { label "[_ monitoring.db_id]" }
		           timestamp            { label "[_ monitoring.timestamp]" }
			   db_size              { label "[_ monitoring.db_size]" }
                           size_content_repository { label "[_ monitoring.size_content_repository]" } 
			} 
                        #timestamp           { label "[_ monitoring.timestamp]" }
			

db_multirow   db_size_itens select_db_itens {}
 
ad_return_template
