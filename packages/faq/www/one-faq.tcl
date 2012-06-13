ad_page_contract {

  View contents of one faq
    @author Elizabeth Wirth (wirth@ybos.net)
    @author Jennie Housman (jennie@ybos.net)
    @creation-date 2000-10-24
 
} {

    faq_id:naturalnum,notnull
}

#/faq/www/one-faq.tcl

set package_id [ad_conn package_id]

set user_id [ad_verify_and_get_user_id]

ad_require_permission $package_id faq_view_faq

db_1row faq_info "select faq_name, separate_p from faqs where faq_id=:faq_id"

set context [list $faq_name]

db_multirow one_question q_and_a_info "select entry_id, faq_id, question, answer, sort_key 
from faq_q_and_as 
where faq_id = :faq_id
order by sort_key"

ad_return_template
