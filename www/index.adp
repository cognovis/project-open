<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">@main_navbar_label@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>


<div class="filter-list">
   <div class="filter">
      <div class="filter-block">
         <div class="filter-title">
            #intranet-expenses.Filter_Expenses#
         </div>


	<form method=get action='index'>
	<%= [export_form_vars orderby] %>

	<table>
	<tr>
	    <td class=form-label><%= [lang::message::lookup "" intranet-expenses.Unassigned_items "Unassigned:"] %></td>
	    <td class=form-widget><%= [im_select -translate_p 0 unassigned $unassigned_p_options $unassigned] %></td>
	</tr>
<!--
	<tr>
	  <td class=form-label>Start Date</td>
	  <td class=form-widget>
	    <input type=textfield name=start_date value=@start_date@>
	  </td>
	</tr>
	<tr>
	  <td class=form-label>End Date</td>
	  <td class=form-widget>
	    <input type=textfield name=end_date value=@end_date@>
	  </td>
	</tr>
-->

	<tr>
	    <td class=form-label><%= [lang::message::lookup "" intranet-expenses.Project "Project"] %></td>
	    <td class=form-widget><%= [im_project_select -include_all 1 -exclude_status_id [im_project_status_closed] project_id $org_project_id] %></td>
	</tr>

	<tr>
	    <td class=form-label><%= [lang::message::lookup "" intranet-expenses.Expense_Type "Type"] %></td>
	    <td class=form-widget><%= [im_category_select -include_empty_p 1  "Intranet Expense Type" expense_type_id $expense_type_id_default] %>

	    </td>
	</tr>

	<tr>
	    <td class=form-label></td>
	    <td class=form-widget><input type=submit></td>
	</tr>


	</table>
	</form>

      </div>
      <if @admin_links@ ne "">

         <hr/>
         <div class="filter-block">
            <div class="filter-title">
       	       #intranet-core.Admin_Links#
            </div>
            <ul>
               @admin_links;noquote@
            </ul>
         </div>

      </if>
   </div>

   <div class="fullwidth-list">
      <%= [im_box_header $page_title] %>
         <listtemplate name="@list_id@"></listtemplate>
      <%= [im_box_footer] %>

      <%= [im_box_header [_ intranet-expenses.Expense_Invoices]] %>
         <listtemplate name="@list2_id@"></listtemplate>
      <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>




