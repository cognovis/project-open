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
    { start_idx:integer "1" }
    { order_by "" }
    { how_many "" }
    { view_name "quality_list" }
    { view_mode "view" }
}

set user_id [ad_maybe_redirect_for_registration]
set page_title "[_ intranet-trans-quality.Quality_Reports]"
set context_bar [ad_context_bar $page_title]
set page_focus "im_header_form.keywords"

set component [im_quality_list_component -project_id $project_id -trans_id $trans_id -edit_id $edit_id  -proof_id $proof_id  -other_id $other_id -person_id $person_id -company_id $company_id -order_by $order_by  -start_idx $start_idx -how_many $how_many -view_name $view_name]



#    @table_header_html;noquote@
#    @table_body_html;noquote@
#    @table_continuation_html;noquote@
#    @button_html;noquote@



#set button_html "
#<tr>
#  <td colspan=[expr $colspan - 3]></td>
#  <td align=center>
#    <input type=submit name=submit value='[_ intranet-trans-quality.Save]'>
#  </td>
#  <td align=center>
#    <input type=submit name=submit value='[_ intranet-trans-quality.Del]'>
#  </td>
#</tr>"


