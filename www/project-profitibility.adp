<if @output_format@ eq "html">
	<%=[im_header]%>
        <%=[im_navbar]%>

        <form>
        <%=[export_form_vars opened_projects]%>

        <table border=0 cellspacing=1 cellpadding=1>
        <tr valign=top>
		<td>
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
			<%= [im_category_select -include_empty_p 1 -include_empty_name [lang::message::lookup "" intranet-core.All "All"] "Intranet Project Status" project_status_id_from_search $project_status_id_from_search] %>
                  </td>
                </tr>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-core.Customer "Customer"]%></td>
                  <td class=form-widget>
                     <%=[im_company_select -include_empty_name [lang::message::lookup "" intranet-core.All "All"] customer_id $customer_id]%>
                  </td>
                </tr>
                <tr>
                  <td class=form-label><%=[lang::message::lookup "" intranet-cust-koernigweber.Written_Order "Written Order?"]%></td>
                  <td class=form-widget>
                        <select name='written_order_form_p'>
                                <option value='0' @written_order_0_selected;noquote@><%=[lang::message::lookup "" intranet-core.All "All"]%></option>
                                <option value='1' @written_order_1_selected;noquote@><%=[lang::message::lookup "" acs-kernel.common_yes "Yes"]%></option>
                                <option value='2' @written_order_2_selected;noquote@><%=[lang::message::lookup "" acs-kernel.common_no "No"]%></option>
                        </select>
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
                <tr>
                  <td class=form-label></td>
                  <td class=form-widget><input type='submit' value='<%=[lang::message::lookup "" intranet-core.Submit "Submit"]%>'></td>
                </tr>
                </table>
        </td>
	<td>&nbsp;&nbsp;&nbsp;</td>
	<td>
	<ul>
            <if @full_view_p@>
		<li><b>Personalkosten (VSI): </b>Anzahl der geloggten Stunden * Kostensatz des MA f&uuml;r AVS Kostenstelle: 9140 unprod. Zeiten prod. MA</li>
		<li><b>Selbstkosten (VSI+Umlage): </b>VSI + Anzahl der geloggten Stunden * Umlage (Umlagekosten der 'Internal Company')</li>
	    </if>
		<li><b>Abrechenbar lt. E/C Preisliste: </b> Anzahl der geloggten Stunden * VK der Preisliste</li>
		<li><b>Sonstige Kosten: </b> Spesen und Ausgaben f&uuml;r Projekte </li>
                <li><b>Lieferantenrechnungen: </b> Summe der im System eingestellter Lieferantenrechnungen</li>
		<li><b>Anspruch: </b> Abrechenbar lt. E/C Preisliste +  Sonstige Kosten (Materialkosten) + Lieferantenrechnungen</li>
		<li><b>Abgrechnet:</b> Summer gestellten Rechnungen</li>
		<li><b>GuV Projekt:</b> Abgerechnet - Anspruch</li>
            <if @full_view_p@>
		<li><b>GuV 1:</b> Abgerechnet - Selbstkosten - Sonstige Kosten - Lieferantenrechnungen</li>
		<li><b>GuV 2:</b> Abgerechnet - Personalkosten - Lieferantenrechnungen - Sonstige Kosten</li>
	    </if>
	</ul>
	</td>
	</tr>
        </table>
        </form>

	<table class="list-table" cellspacing="1" cellpadding="3" summary="Data for project_list">
	<if @first_request_p@ eq "0">
	<thead>
      	<tr class="list-header">
            <th class="list-table" align="left" id="">@label_client;noquote@</th>
	    <th class="list-table" align="left" id="">@label_project_name;noquote@</th>
       	    <th class="list-table" align="center" id="">@label_written_order;noquote@</th>
       	    <th class="list-table" align="center" id="">@label_project_status;noquote@</th>
	    <if @full_view_p@>	
            	<th class="list-table" align="right" id="">@label_staff_costs;noquote@</th>
	        <th class="list-table" align="right" id="">@label_target_benefit;noquote@</th>
	    </if>
            <th class="list-table" align="right" id="">@label_costs_based_on_matrix;noquote@</th>
            <th class="list-table" align="right" id="">@label_costs_material;noquote@</th>
            <th class="list-table" align="right" id="">@label_provider_bills;noquote@</th>
            <th class="list-table" align="right" id="">@label_invoiceable_total;noquote@</th>
            <th class="list-table" align="right" id="">@label_invoiced;noquote@</th>
            <th class="list-table" align="right" id="">@label_profit_and_loss_project;noquote@</th>
            <if @full_view_p@>
	            <th class="list-table" align="right" id="">@label_profit_and_loss_one;noquote@</th>
        	    <th class="list-table" align="right" id="">@label_profit_and_loss_two;noquote@</th>
	    </if>
	</tr>
	</thead>
	</if>
    	<tbody>	
	<if @i@ ne 1>
		<multiple name='project_list'>
			<if @project_list.project_type_id@ ne 100>
			<tr class="odd">
			  <td class="list-table"><a href='/intranet/companies/view?company_id=@project_list.company_id@'>@project_list.company_name@</a></td>
			  <td class="list-table">@project_list.open_gif;noquote@<a href='/intranet/projects/view?project_id=@project_list.project_id@'>@project_list.project_name@</a></td>
			  <td class="list-table" align="center">@project_list.written_order_p@</td>
			  <td class="list-table" align="center">@project_list.project_status@</td>
                          <if @full_view_p@>
				  <td class="list-table" align="right">@project_list.staff_costs@</td>
				  <td class="list-table" align="right">@project_list.target_benefit@</td>
			  </if>
			  <td class="list-table" align="right">@project_list.amount_invoicable_matrix@</td>
			  <td class="list-table" align="right">@project_list.costs_material;noquote@</td>
			  <td class="list-table" align="right">@project_list.provider_bills@</td>
			  <td class="list-table" align="right">@project_list.invoiceable_total@</td>
			  <td class="list-table" align="right">@project_list.sum_invoices@</td>
			  <td class="list-table" align="right">@project_list.profit_and_loss_project@</td>
		          <if @full_view_p@>
				  <td class="list-table" align="right">@project_list.profit_and_loss_one@</td>
				  <td class="list-table" align="right">@project_list.profit_and_loss_two@</td>
			  </if>
	  		</tr>
			</if>
  		</multiple>
	   	</tbody>	
		<if @opened_projects@ eq 0 or @opened_projects@ eq "">
	   		<tfooter>	
	                <tr class="odd">
        	          <td class="list-table"></td>
                	  <td class="list-table"></td>
	                  <td class="list-table" align="center"></td>
        	          <td class="list-table" align="center"></td>
                	  <if @full_view_p@>
	                	  <td class="list-table" align="right">@total__amount_costs_staff@</td>
	        	          <td class="list-table" align="right">@total__target_benefit@</td>
			  </if>
                	  <td class="list-table" align="right">@total__amount_invoicable_matrix@</td>
	                  <td class="list-table" align="right">@total__total_expenses_billable@<br>>@total__total_expenses_not_billable@</td>
        	          <td class="list-table" align="right">@total__total_provider_bills@</td>
                	  <td class="list-table" align="right">@total__invoiceable_total_var@<!--Erloesfaehig/Anspruch --></td> 
	                  <td class="list-table" align="right">@total__sum_invoices_value@</td>
        	          <td class="list-table" align="right">@total__profit_and_loss_project_var@</td>
                	  <if @full_view_p@>
	                	  <td class="list-table" align="right">@total__profit_and_loss_one_var@</td>
	        	          <td class="list-table" align="right">@total__profit_and_loss_two_var@</td>
			  </if>
                	</tr>
	   		</tfooter>	
		</if>
	</if>
    </table>
    <if @err_mess@ ne "">
	    <%=<h2> [lang::message::lookup "" intranet-cust-koernigweber.PleaseNote "Please note:"]</h2>%>
	    @err_mess;noquote@ 
    </if>
</if>
<%= [im_footer] %>