<table valign="top" align="center" width="350px">
  <multiple name=company_info>
    <if @company_info.heading@ not nil>
      <tr>
        <td colspan="2" align="left">
          <h3 class="contact-title">@company_info.heading@</h3>
        </td>
      </tr>
    </if>
    <tr>
      <td align="right" valign="top" class="attribute">@company_info.field@:</td>                                                         
      <td align="left" valign="top" class="value">@company_info.value@</td>                                                                                    
    </tr>
  </multiple>    
  <if @write@ and @edit_project_base_data_p@>
    <tr> 
      <td>&nbsp; </td>
      <td> 
        <form action=/intranet/projects/new method=POST>
	  <input type="hidden" name="project_id" value="@project_id@">
	  <input type="hidden" name="return_url" value="@return_url@">
	  <input type=submit value="#intranet-core.Edit#" name=submit3>
        </form>
      </td>
    </tr>
  </if>
</table>