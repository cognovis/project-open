<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@costs_navbar_html;noquote@</property>

<div class="filter-list">
   <div class="filter">
      <div class="filter-block">
         <div class="filter-title">
            #intranet-core.Filter_Projects#
         </div>


	<table>
	<tr>
	  <td>
		<form method=GET action='/intranet-timesheet2-invoices/invoices/new'>
		<%= [export_form_vars start_idx order_by how_many target_cost_type_id view_name include_subprojects_p letter] %>
		<table border=0 cellpadding=0 cellspacing=0>
		<tr>
		  <td valign=top>
<%= [lang::message::lookup "" intranet-timesheet2-invoices.Project_br_Status "Project<br>Status"] %>:
    		  </td>
		  <td valign=top><%= [im_category_select -include_empty_p 1 "Intranet Project Status" project_status_id $project_status_id] %></td>
		</tr>

		<tr>
		  <td valign=top>
		  <%= [lang::message::lookup "" intranet-timesheet2-invoices.Project_br_Type "Project<br>Type"] %>:
		  </td>
		  <td valign=top>
		    <%= [im_category_select -include_empty_p 1 "Intranet Project Type" project_type_id $project_type_id] %>
		  </td>
		</tr>

		<tr>
		  <td valign=top>
		      <%= [lang::message::lookup "" intranet-core.Customer "Customer"] %>:
		  </td>
		  <td valign=top>
		      <%= [im_company_select -include_empty_name "All" company_id $filter_company_id "" "CustOrIntl"] %>
		  </td>
		</tr>

		<tr>
		  <td valign=top>&nbsp;</td>
		  <td valign=top>
			  <input type=submit value=Go name=submit>
		  </td>
		</tr>

		</table>
		</form>
	  </td>
	</tr>
	<tr>
	  <td>#intranet-timesheet2-invoices.lt_To_create_a_new_invoi#</td>
	</tr>
	</table>


      </div>

      <hr/>
      <%= [im_navbar_tree -label "main"] %>

   </div>

   <div class="fullwidth-list">
      <%= [im_box_header $page_title] %>

	<form method=POST action='new-2'>
	<%=[export_form_vars target_cost_type_id]%>
	<table width="100%" cellpadding=2 cellspacing=2 border=0>
	@table_header_html;noquote@
	@table_body_html;noquote@
	@table_continuation_html;noquote@
	@submit_button;noquote@
	</table>
	</form>

     <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>

