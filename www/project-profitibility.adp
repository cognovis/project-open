<if @output_format@ eq "html">
	<%=[im_header]%>
        <%=[im_navbar]%>

        <form>
        <%=[export_form_vars opened_projects]%>

        <table border=0 cellspacing=1 cellpadding=1>
        <tr valign=top><td>

                <table border=0 cellspacing=1 cellpadding=1>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-core.Start_Date "Start Date"]%></td>
                  <td class=form-widget>
                    <input type=textfield name="start_date" id="start_date" value=@start_date@>
                    <input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('start_date', 'y-m-d');" >
                  </td>
                </tr>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-core.End_Date "End Date"]%></td>
                  <td class=form-widget>
                    <input type=textfield name="end_date" id="end_date" value=@end_date@>
                    <input type="button" style="height:20px; width:20px; background: url('/resources/acs-templating/calendar.gif');" onclick ="return showCalendar('end_date', 'y-m-d');" >
                  </td>
                </tr>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-core.Project_Status "Project Status"]%></td>
                  <td class=form-widget>
			<%= [im_category_select -include_empty_p 1 "Intranet Project Status" project_status_id] %>
                  </td>
                </tr>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-core.Customer "Customer"]%></td>
                  <td class=form-widget>
                     <%=[im_company_select customer_id $customer_id]%>
                  </td>
                </tr>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-cust-koernigweber.Written_Order "Written Order?"]%></td>
                  <td class=form-widget>
                        <select name='written_order_form_p'>
                                <option value='0' @written_order_0_selected;noquote@><%=[lang::message::lookup "" intranet-core.all "All"]%></option>
                                <option value='1' @written_order_1_selected;noquote@><%=[lang::message::lookup "" acs-kernel.common_yes "Yes"]%></option>
                                <option value='2' @written_order_2_selected;noquote@><%=[lang::message::lookup "" acs-kernel.common_no "No"]%></option>
                        </select>
                  </td>
                </tr>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-core.employees "Employees"]%></td>
                  <td class=form-widget>
                     <%=[im_user_select -include_empty_p 1 -include_empty_name [lang::message::lookup "" intranet-core.all "All"] -group_id [im_profile_employees] "user_id_from_search" $user_id_from_search]%>
                  </td>
                </tr>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-reporting.Output_Format "Output Format"]%></td>
                  <td class=form-widget>
                        <nobr>
                                <input name='output_format' value='html' checked='checked' type='radio'>HTML &nbsp;
                                <input name='output_format' value='csv' type='radio'>CSV
                        </nobr>
                  </td>
                </tr>
                <tr>
                  <td class=form-label></td>
                  <td class=form-widget><input type='submit' value='<%=[lang::message::lookup "" intranet-core.Submit "Submit"]%>'></td>
                </tr>
                </table>
        </td></tr>
        </table>
        </form>

	<table class="list-table" cellspacing="1" cellpadding="3" summary="Data for project_list">
	<thead>
      	<tr class="list-header">
            <th class="list-table" align="left" id="project_list_company_name">@label_client;noquote@</th>
	    <th class="list-table" align="left" id="project_list_project_name">@label_project_name;noquote@</th>
       	    <th class="list-table" align="center" id="project_list_written_order">@label_written_order;noquote@</th>
            <th class="list-table" align="right" id="project_list_cost_timesheet_logged_cache_l">@label_staff_costs;noquote@</th>
            <th class="list-table" align="right" id="project_list_target_benefit">@label_target_benefit;noquote@</th>
            <th class="list-table" align="right" id="project_list_target_benefit">@label_costs_based_on_matrix;noquote@</th>
            <th class="list-table" align="right" id="project_list_target_benefit">@label_costs_material;noquote@</th>
            <th class="list-table" align="right" id="project_list_target_benefit">@label_invoiceable_total;noquote@</th>
            <th class="list-table" align="right" id="project_list_target_benefit">@label_invoiced;noquote@</th>
            <th class="list-table" align="right" id="project_list_target_benefit">@label_profit_and_loss_project;noquote@</th>
            <th class="list-table" align="right" id="project_list_target_benefit">@label_profit_and_loss_one;noquote@</th>
            <th class="list-table" align="right" id="project_list_target_benefit">@label_profit_and_loss_two;noquote@</th>
	</tr>
	</thead>
    	<tbody>	
	<if @i@ ne 1>
		<multiple name='project_list'>
			<if @project_list.project_type_id@ ne 100>
			<tr class="odd">
			  <td class="list-table"><a href='/intranet/companies/view?company_id=@project_list.company_id@'>@project_list.company_name@</a></td>
			  <td class="list-table">@project_list.open_gif;noquote@<a href='/intranet/projects/view?project_id=@project_list.project_id@'>@project_list.project_name@</a></td>
			  <td class="list-table" align="center">@project_list.written_order_p@</td>
			  <td class="list-table" align="right">@project_list.staff_costs@</td>
			  <td class="list-table" align="right">@project_list.target_benefit@</td>
			  <td class="list-table" align="right">@project_list.amount_invoicable_matrix@</td>
			  <td class="list-table" align="right">@project_list.costs_material@</td>
			  <td class="list-table" align="right">@project_list.invoiceable_total@</td>
			  <td class="list-table" align="right">@project_list.sum_invoices@</td>
			  <td class="list-table" align="right">@project_list.profit_and_loss_project@</td>
			  <td class="list-table" align="right">@project_list.profit_and_loss_one@</td>
			  <td class="list-table" align="right">@project_list.profit_and_loss_two@</td>
	  		</tr>
			</if>
  		</multiple>
   	</tbody>	
   	<tfooter>	
                <tr class="odd">
                  <td class="list-table"></td>
                  <td class="list-table"></td>
                  <td class="list-table" align="center"></td>
                  <td class="list-table" align="right">@total__amount_costs_staff@</td>
                  <td class="list-table" align="right">@total__target_benefit@</td>
                  <td class="list-table" align="right">@total__amount_invoicable_matrix@</td>
                  <td class="list-table" align="right">@total__total_expenses@</td>
                  <td class="list-table" align="right">@total__invoiceable_total_var@<!--erloesfaehig --></td> 
                  <td class="list-table" align="right">@total__sum_invoices_value@</td>
                  <td class="list-table" align="right">@total__profit_and_loss_project_var@</td>
                  <td class="list-table" align="right">@total__profit_and_loss_one_var@</td>
                  <td class="list-table" align="right">@total__profit_and_loss_two_var@</td>
                </tr>
   	</tfooter>	
	</if>
    </table>
</if>