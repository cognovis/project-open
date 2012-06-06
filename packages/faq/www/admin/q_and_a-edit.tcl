#faq/www/admin/q_and_a-edit.tcl

ad_page_contract {

  View contents of one Q&A
    @author Elizabeth Wirth (wirth@ybos.net)
    @author Jennie Housman (jennie@ybos.net)
    @creation-date 2000-10-24
 
} {

    entry_id:naturalnum,notnull
} -properties {
    entry_id:onevalue
}

set package_id [ad_conn package_id]

ad_require_permission $package_id faq_modify_faq

set action "q_and_a-edit-2"
set submit_label [_ faq.Update_This_QA]

set user_id [ad_verify_and_get_user_id]

db_1row q_and_a_info "select question, answer,faq_name,qa.faq_id
                      from faq_q_and_as qa, faqs f
                      where entry_id = :entry_id
                      and f.faq_id = qa.faq_id"

set context [list [list "one-faq?faq_id=$faq_id" "$faq_name"] "One Q&A"]

set delete_url "q_and_a-delete?[export_vars { entry_id faq_id }]"

ad_return_template
