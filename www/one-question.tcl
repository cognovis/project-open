#faq/www/one-question.tcl

ad_page_contract {

  View contents of one Q&A
    @author Elizabeth Wirth (wirth@ybos.net)
    @author Jennie Housman (jennie@ybos.net)
    @creation-date 2000-10-24
 
} {

    entry_id:naturalnum,notnull
}

set package_id [ad_conn package_id]

ad_require_permission $package_id faq_view_faq

set user_id [ad_verify_and_get_user_id]

db_1row q_and_a_info "select question, answer,faq_name, f.faq_id 
                       from faq_q_and_as qa, faqs f
                       where entry_id = :entry_id
                         and qa.faq_id = f.faq_id"

set context [list [list "one-faq?faq_id=$faq_id" $faq_name] [_ faq.One_Question]]


ad_return_template
