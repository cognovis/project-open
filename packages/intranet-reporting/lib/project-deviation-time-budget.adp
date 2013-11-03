<if @output_format@ eq "html">
	<%=[im_header]%>
        <%=[im_navbar]%>

        <form action='project-deviation-time-budget' id='intranet-reporting-project-deviation-time-budget'>
        <%=[export_form_vars opened_projects]%>

        <table border=0 cellspacing="1" cellpadding="1" width="100%">
        <tr valign=top>
		<td>
                <table border=0 cellspacing=1 cellpadding=1 width='420px'>
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
                  <td class=form-label><%=[lang::message::lookup "" intranet-core.Customer "Customer"]%></td>
                  <td class=form-widget>
                     <%=[im_company_select -include_empty_name [lang::message::lookup "" intranet-core.All "All"] customer_id $customer_id]%>
                  </td>
                </tr>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-core.Project_Name "Project Name"]%></td>
                  <td class=form-widget>
                        <%= [im_project_select -include_empty_p 1 -exclude_subprojects_p 0 -include_empty_name [lang::message::lookup "" intranet-core.All "All"] project_id $project_id_from_filter] %>
                  </td>
                </tr>
<!--
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-core.Project_Status "Project Status"]%></td>
                  <td class=form-widget>
			<%= [im_category_select -include_empty_p 1 -include_empty_name [lang::message::lookup "" intranet-core.All "All"] "Intranet Project Status" project_status_id_from_search $project_status_id_from_search] %>
                  </td>
                </tr>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-core.employees "Employees"]%></td>
                  <td class=form-widget>
                     <%=[im_user_select -include_empty_p 1 -include_empty_name [lang::message::lookup "" intranet-core.All "All"] -group_id [im_profile_employees] "user_id_from_search" $user_id_from_search]%>
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
--> 
                <tr>
                  <td class=form-label></td>
                  <td class=form-widget><input type='submit' value='<%=[lang::message::lookup "" intranet-core.Submit "Submit"]%>'></td>
                </tr>
                </table>
        </td>
	<td>&nbsp;&nbsp;&nbsp;</td>
	<td>
	<ul>
		<li><b>@label_client;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Client_Cmt]%></li>
		<li><b>@label_project_name;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Project_name_Cmt]%></li>
		<li><b>@label_project_manager;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Project_manager_Cmt]%></li>
		<li><b>@label_end_date;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_End_Date_Cmt]%></li>
        <li><b>@label_percent_completed;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Percent_Completed_Cmt]%></li>
		<li><b>@label_project_budget_hours;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Project_Budget_Hours_Cmt]%></li>
		<li><b>@label_hours_logged;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Hours_Logged_Cmt]%></li>
		<li><b>@label_deviation_target;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Deviation_Target_Cmt]%><!--Aktuelle Abweichung (Budget (Std.) * Fortschritt - Verfahrene Std.)--> </li>
		<li><b>@label_projection_hours;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Projection_Hours_Cmt]%> <!--Verfahrene Stunden / Budget Std. / Fortschritt * Budget Std.--> </li>
		<li><b>@label_delta_projection_hours_budget;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Delta_Projection_Hours_Budget_Cmt]%> <!-- Budget (Std.) - Prognose --> </li>
		<li><b>@label_project_budget;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Project_Budget_Cmt]%></li>
		<li><b>@label_delta_budget_costs;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Delta_Budget_Costs_Cmt]%> <!-- (Bestellwert * Fortschritt) - Aufgelaufene Kosten --></li>
		<li><b>@label_projection_costs;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Projection_Costs_Cmt]%> <!-- Aufgelaufen Kosten / Bestellwert / Fortschritt * Bestellwert)--></li>
		<li><b>@label_delta_budget_projection;noquote@:</b> <%=[_ intranet-reporting.Project_Deviation_Time_Budget_Delta_Budget_Projection_Cmt]%> <!-- Bestellwert - Prognose Kosten --> </li>
	</ul>
	</td>
	</tr>
        </table>
        </form>
	<br>
	<table class="list-table" cellspacing="1" cellpadding="3" summary="Data for project_list">
	<if @first_request_p@ eq "0">
		<thead>
      	<tr class="list-header">
        <th class="list-table" align="left" id="">@label_client;noquote@</th>
	    <th class="list-table" align="left" id="">@label_project_name;noquote@</th>
   	    <th class="list-table" align="center" id="">@label_project_manager;noquote@</th>
   	    <th class="list-table" align="center" id="">@label_end_date;noquote@</th>
        <th class="list-table" align="right" id="">@label_percent_completed;noquote@</th>
	    <th class="list-table" align="right" id="">@label_project_budget_hours;noquote@</th>
	    <th class="list-table" align="right" id="">@label_hours_logged;noquote@</th>
        <th class="list-table" align="right" id="">@label_deviation_target;noquote@</th>
        <th class="list-table" align="right" id="">@label_projection_hours;noquote@</th>
        <th class="list-table" align="right" id="">@label_delta_projection_hours_budget;noquote@</th>
        <th class="list-table" align="right" id="">@label_project_budget;noquote@</th>
        <th class="list-table" align="right" id="">@label_costs_matrix;noquote@</th>
        <th class="list-table" align="right" id="">@label_delta_budget_costs;noquote@</th>
        <th class="list-table" align="right" id="">@label_projection_costs@</th>
   	    <th class="list-table" align="right" id="">@label_delta_budget_projection;noquote@</th>
	    </if>
		</thead>
	</if>
    	<tbody>	
	<if @i@ ne 1>
		<multiple name='project_list'>
			<if @project_list.project_type_id@ ne 100>
				<tr class="odd">
				  <td class="list-table"><a href='/intranet/companies/view?company_id=@project_list.company_id@'>@project_list.company_name@</a></td>
				  <td class="list-table">@project_list.open_gif;noquote@&nbsp;<a href='/intranet/projects/view?project_id=@project_list.project_id@'>@project_list.project_name@</a></td>
				  <td class="list-table" align="center">@project_list.project_manager@</td>
				  <td class="list-table" align="center">@project_list.end_date@</td>
				  <td class="list-table" align="right">@project_list.percent_completed@</td>
				  <td class="list-table" align="right">@project_list.project_budget_hours@</td>
				  <td class="list-table" align="right">@project_list.hours_logged@</td>
				  <td class="list-table" align="right">@project_list.deviation_target@</td>
				  <td class="list-table" align="right">@project_list.projection_hours;noquote@</td>
				  <td class="list-table" align="right">@project_list.delta_projection_hours_budget@</td>
				  <td class="list-table" align="right">@project_list.project_budget@</td>
				  <td class="list-table" align="right">@project_list.costs_matrix@</td>
				  <td class="list-table" align="right">@project_list.delta_budget_costs@</td>
				  <td class="list-table" align="right">@project_list.projection_costs;noquote@</td>
				  <td class="list-table" align="right">@project_list.delta_budget_projection@</td>
	  			</tr>
			</if>
  		</multiple>
	   	</tbody>	

		<if @opened_projects@ eq 0 or @opened_projects@ eq "">
<!--
	   		<tfooter>	
	                <tr class="odd">
        	          <td class="list-table"></td>
	                  <td class="list-table" align="center"></td>
	   		</tfooter>	
-->
		</if>
	</if>
    </table>
    <if @err_mess@ ne "">
	    <%=<h2> [lang::message::lookup "" intranet-reporting.PleaseNote "Please note:"]</h2>%>
	    @err_mess;noquote@ 
    </if>
</if>

<%=[im_footer]%>