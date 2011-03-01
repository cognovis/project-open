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

set user_id [ad_conn user_id]

db_1row question_info ""

set context [list [list "one-faq?faq_id=$faq_id" $faq_name] [_ faq.One_Question]]


ad_return_template
