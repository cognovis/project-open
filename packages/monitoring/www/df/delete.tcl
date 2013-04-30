ad_page_contract {

    delete all data 
} {
}

set title "[_ monitoring.Delete]"
set context [list $title] 


ad_form -name confirm_delete -export {item_id} -form {
   {confirmation:text(radio) {label "Delete"}
	{options
	    {{"[_ monitoring.Yes]" t }
	     {"[_ monitoring.No]" f }}	}
	     {value f}}
    
	
} -on_submit {
	if {$confirmation} {
	    db_transaction {
	        db_dml do_delete  "delete from ad_monitoring_top_df_item"  
		db_dml do_delete2  "delete from ad_monitoring_df" 
            } on_error {
    		ad_return_error "Oppss" "Error: $errmsg"
		ad_script_abort
	    }
	    
	    ad_returnredirect "index"
            ad_script_abort
	} else {
	    ad_returnredirect "index"
            ad_script_abort
	}
}

