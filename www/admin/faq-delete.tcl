#/faq/admin/faq-delete.tcl

ad_page_contract {
    
    delete an FAQ
    @author Elizabeth Wirth (wirth@ybos.net)
    @author Jennie Housman (jennie@ybos.net)
    @creation-date 2000-10-24

} {

    faq_id:naturalnum,notnull

}
set package_id [ad_conn package_id]

permission::require_permission -object_id  $package_id -privilege faq_delete_faq

db_transaction {
    db_exec_plsql delete_faq {
	begin
	   faq.delete_faq (
		    faq_id => :faq_id
	        );
	end;
    }
}

ad_returnredirect "index"