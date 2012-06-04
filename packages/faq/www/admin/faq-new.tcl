#faq/www/admin/faq-new.tcl

ad_page_contract {

    Displays a form for creating a new faq.

    @author Elizabeth Wirth (wirth@ybos.net)
    @author Jennie Housman (jennie@ybos.net)
    @creation-date 2000-10-24
} {
} -properties {
    context:onevalue
    faq_id:onevalue
    title:onevalue
    action:onevalue
    submit_label:onevalue
    faq_name:onevalue
  
}

ad_require_permission [ad_conn package_id] faq_create_faq

set context {[_ faq.Create_an_FAQ]}
set title [_ faq.Create_an_FAQ]
set action "faq-new-2"
set submit_label [_ faq.Create_FAQ]
set faq_name ""


set faq_id [db_nextval acs_object_id_seq]

ad_return_template
