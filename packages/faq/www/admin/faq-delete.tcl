#/faq/admin/faq-delete.tcl

ad_page_contract {
    
    delete an FAQ, also deletes entries in acs_named_objects for categories
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
    db_dml delete_named_object "delete from acs_named_objects where object_id in (select entry_id from faq_q_and_as where faq_id = :faq_id)"
}

ad_returnredirect "index"