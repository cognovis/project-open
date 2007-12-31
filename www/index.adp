<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">context</property>
<property name="main_navbar_label">user</property>

<div class="filter-list">
   <div class="filter">
      <div class="filter-block">
        <div class="filter-title">
	    #intranet-core.Filter_Users#
        </div>

		<form method=get action='/intranet-freelance/index'>
		<%= [export_form_vars user_group_name start_idx order_by how_many view_name letter] %>
		
		<table border=0 cellpadding=1 cellspacing=1>
		  @skill_filter_html;noquote@
		  <tr>
		    <td class="form-label"><%= [lang::message::lookup "" intranet-freelance.Recruiting_Status1 "Rec.<br>Status"] %></td>
		    <td class="form-widget">
		      <%= [im_select rec_status_id $rec_stati $rec_status_id] %>
		    </td>
		  </tr>
		  <tr>
		    <td class="form-label"><%= [lang::message::lookup "" intranet-freelance.lt_Recruiting_Test_Result "Rec. Test<br>Result"] %></td>
		    <td class="form-widget">
		      <%= [im_select rec_test_result_id $rec_test_results $rec_test_result_id] %>
		    </td>
		  </tr>
		  <tr>
		    <td class="form-label"><%= [lang::message::lookup "" intranet-freelance.Worked_already_with_customer "Worked<br>with cust"] %></td>
		    <td class="form-widget">
		      <%= [im_company_select -include_empty_name "All" worked_with_company_id $worked_with_company_id "" "Customer"] %>
		    </td>
		  </tr>
		  <tr>
		    <td class="form-label"></td>
		    <td class="form-widget">
		      <input type=submit value="#intranet-freelance.Go#" name=submit>
		    </td>
		  </tr>
		</table>
		</form>


      </div>

<if @admin_html@ ne "">
      <div class="filter-block">
         <div class="filter-title">
            #intranet-core.Admin_Users#
         </div>
         <ul>
         @admin_html;noquote@
         </ul>
      </div>
</if>

      <%= [im_navbar_tree -label "main"] %>

      </div>
   </div>

   <div class="fullwidth-list">
      <%= [im_box_header $page_title] %>
         <table>
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
         </table>
     <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>




<%= $navbar_html %>

