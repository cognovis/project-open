ad_page_contract {

    delete all data 
} {
}

set title "[_ monitoring.Delete]"
set context [list [list "index2" "Top"] "$title"] 


ad_form -name confirm_delete -export {item_id} -form {
   {confirmation:text(radio) {label "[_ monitoring.Delete]"}
	{options
	    {{"[_ monitoring.Yes]" t }
	     {"[_ monitoring.No]" f }}	}
	     {value f}}
    
	
} -on_submit {
	if {$confirmation} {
	    #db_transaction {
	        db_dml do_delete   "delete from ad_monitoring_db" 
            #} on_error {
    		#ad_return_error "Oppss" "Error: $errmsg"
		#ad_script_abort
	    #}
	    
	    ad_returnredirect "index2"
            ad_script_abort
	} else {
	    ad_returnredirect "index2"
            ad_script_abort
	}
}

