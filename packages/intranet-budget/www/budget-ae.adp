<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<form action=new-2 name=budget method=POST>
  <input type="hidden" name="return_url" value="@return_url@">
  <input type="hidden" name="budget_id" value="@budget_id@">
  <input type="hidden" name="project_id" value="@project_id@">
      
<!-- the list of task sums, distinguised by type and UOM -->
<table width="100%" align=right border=0>
  <tr align=left> 
    <td class=rowtitle colspan=3>#intranet-cost.Cost_Items#</td>
  </tr>
  <tr align=center> 
          <td class=rowtitle>#intranet-core.Description#</td>
          <td class=rowtitle>#intranet-cost.Type#</td>
          <td class=rowtitle>#intranet-cost.Amount#</td>
        </tr>
	@amount_element_html;noquote@
  </tr>

  <tr align=left> 
    <td class=rowtitle colspan=3>#intranet-budget.Hours#</td>
  </tr>
  <tr align=center> 
          <td class=rowtitle>#intranet-core.Description#</td>
          <td class=rowtitle>#intranet-core.Department#</td>
          <td class=rowtitle>#intranet-timesheet2.Hours#</td>
        </tr>
	@hour_element_html;noquote@
  <tr>
    <td align=right colspan=3>
      <input type="submit" name="submit" value="#intranet-budget.New_Provider_Estimation#">
	  </td>
  </tr>

</table>

    
</form>     
