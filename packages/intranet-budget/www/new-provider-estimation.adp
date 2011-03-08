<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>

<div class="component">
     <table width="100%">
     <tr>
     <td>
       <div class="component_header_rounded" >
           <div class="component_header">
	         <div class="component_title">#intranet-budget.budget_estimation#</div>
		       <div class="component_icons"></div>
		           </div>
			     </div>
			     </td>
			     </tr>
			     <tr>
			     <td colspan=2>
<div class = "component_body">
<form action=new-provider-estimation-2 name=invoice method=POST>
<%= [export_form_vars invoice_id return_url] %>


<!-- the list of task sums, distinguised by type and UOM -->
<table width=100% align=left border=0 class="list-table">
  <tr align=center> 
    <td class=rowtitle>#intranet-invoices.Description#</td>
    <td class=rowtitle>#intranet-budget.Cost_Type#</td>
    <td class=rowtitle>#intranet-invoices.Units#</td>
    <td class=rowtitle>#intranet-invoices.Rate#</td>
  </tr>
  @task_sum_html;noquote@  
  <tr>
    <td align=right>&nbsp;</td>
    <td align=right>&nbsp;</td>
    <td align=right>&nbsp;</td>
    <td align=right>
      <input type="hidden" name="cost_type_id" value="@cost_type_id@">
      <input type="hidden" name="project_id" value="@project_id@">
      <input type="hidden" name="customer_id" value="@customer_id@">
      <input type="submit" name="submit" value="#intranet-budget.New_Provider_Estimation#"></td>
  </tr>
  <table>
    

</form>     
</div>  
	  <div class="component_footer">
	      <div class="component_footer_hack"></div>
	        </div>

		</td>
		</tr>
		</table>
</div>