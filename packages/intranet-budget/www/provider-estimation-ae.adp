<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<form action=new-2 name=cost method=POST>
  <input type="hidden" name="return_url" value="@return_url@">
  <input type="hidden" name="cost_type_id" value="@cost_type_id@">
  <input type="hidden" name="project_id" value="@project_id@">
      
<!-- the list of task sums, distinguised by type and UOM -->
<table width="100%" align=right border=0>
  <tr align=left> 
    <td class=rowtitle>#intranet-budget.Provider_Estimation#</td>
  </tr>
  <tr align=center> 
    <td valign=top>
      <table width="100%" align=right border=0>
        <tr align=center> 
          <td class=rowtitle>#intranet-budget.Name#</td>
          <td class=rowtitle>#intranet-budget.Type#</td>
          <td class=rowtitle>#intranet-budget.Status#</td>
        </tr>
        <tr align=center>
          <td align=left valign=top><input type=text name=cost_name size=40></td>
	  <td align=left valign=top>@cost_type;noquote@</td>
	  <td align=left valign=top>@cost_status_select;noquote@</td>
        </tr>
     </table>
    </td>
  </tr>
  <tr align=left> 
    <td class=rowtitle>#intranet-budget.Estimation_Items#</td>
  </tr>
  <tr align=center> 
    <td valign=top>
      <table width="100%" align=right border=0>
        <tr align=center> 
          <td class=rowtitle>#intranet-budget.Description#</td>
          <td class=rowtitle>#intranet-budget.Type#</td>
          <td class=rowtitle>#intranet-budget.Units#</td>
          <td class=rowtitle>#intranet-budget.Rate#</td>
        </tr>
	@task_sum_html;noquote@

      </table>
    </td>
  </tr>
  <tr>
    <td valign=top>
      <table width="100%" align=right border=0>
        <tr>
          <td align=right>&nbsp;</td>
          <td align=right>&nbsp;</td>
          <td align=right>&nbsp;</td>
          <td align=right>
            <input type="submit" name="submit" value="#intranet-budget.Save_Provider_Estimation#">
	  </td>
        </tr>
      <table>
    </td>
  </tr>

</table>

    
</form>     
