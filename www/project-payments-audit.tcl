# /www/intranet/payments/project-payments-audit.tcl

ad_page_contract {
    Purpose: Shows audit trail for a project

    @param group_id Group for which to generate the audit trail

    @author mbryzek@arsdigita.com
    @creation-date Jan 2000

    @cvs-id project-payments-audit.tcl,v 3.5.6.7 2000/09/22 01:38:42 kevin Exp
} {
    group_id:naturalnum,notnull
}


set project_name [db_string get_project_name \
	"select group_name 
         from user_groups
         where group_id = :group_id"]

set page_title "<#_ Payments audit for %project_name%#>"
set context_bar [im_context_bar [list "[im_url_stub]/projects/" "<#_ Projects#>"] [list "[im_url_stub]/projects/view?[export_url_vars group_id]" $project_name] [list index?[export_url_vars group_id] "<#_ Payments#>"] "<#_ Audit trail#>"]

set page_content [ad_audit_trail $group_id im_project_payments_audit im_project_payments group_id]

doc_return  200 text/html [im_return_template]


