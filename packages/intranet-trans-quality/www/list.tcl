# packages/intranet-trans-quality/www/list.tcl

# ---------------------------------------------------------------
# Page Contract
# ---------------------------------------------------------------

ad_page_contract { 
    List all quality reports 

    @author frank.bergmann@project-open.com
} {
    { project_id 0 }
    { trans_id 0 }
    { edit_id 0 }
    { proof_id 0 }
    { other_id 0 }
    { person_id 0 }
    { company_id 0 }
    { start_idx:integer 0 }
    { order_by "" }
    { how_many "" }
    { quality_group "" }
    { view_name "transq_task_list" }
    { view_mode "view" }
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-trans-quality.Quality_Reports]"
set context_bar [im_context_bar $page_title]
set page_focus "im_header_form.keywords"

if {![im_permission $user_id view_trans_quality]} { 
    ad_return_complaint 1 "<li>[_ intranet-core.lt_You_have_insufficient_6]"
    return
}

set component [im_quality_list_component -project_id $project_id -quality_group $quality_group -trans_id $trans_id -edit_id $edit_id  -proof_id $proof_id  -other_id $other_id -person_id $person_id -company_id $company_id -order_by $order_by  -start_idx $start_idx -how_many $how_many -view_name $view_name]

