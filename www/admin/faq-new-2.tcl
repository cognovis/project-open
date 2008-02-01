#faq/www/admin/faq-new-2.tcl

ad_page_contract {

    Create a new faq.
    @author Elizabeth Wirth (wirth@ybos.net)
    @author Jennie Housman (jennie@ybos.net)
    @creation-date 2000-10-24

    @param faq_id    The ID of the new faq to be created (debounce)
    @param faq_name  The short name of the faq

} {
    faq_id:integer,notnull
    faq_name:notnull,trim
    separate_p:notnull
}
set package_id [ad_conn package_id]

set user_id [ad_verify_and_get_user_id]
set creation_ip [ad_conn host]

ad_require_permission $package_id faq_create_faq

db_transaction {
    db_exec_plsql create_faq {
	begin
	  :1 := faq.new_faq (
		    faq_id => :faq_id,
	            faq_name => :faq_name,
		    separate_p => :separate_p,
		    creation_user => :user_id,
                    creation_ip => :creation_ip,
	            context_id => :package_id
	        );
	end;
    }
}
# on error ...

ad_returnredirect "."
