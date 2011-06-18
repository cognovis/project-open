<table valign="top" align="center" width="100%" border=1>
  <tr>
      <td colspan="2" align="center">
         <h3 class="contact-title">@ticket_id@</h3>
      </td>
  </tr>
  <multiple name="ticket_info">
    <tr VALIGN=TOP> 
      <td>@ticket_info.pretty_name;noquote@</td>
      <td>@ticket_info.value;noquote@</td>
    </tr>
 </multiple>  
  <if @write@ eq 1>
    <tr> 
      <td>&nbsp; </td>
      <td> 
        <form action=/intranet-cognovis/tickets/ticket-ae method=POST>
	  <input type="hidden" name="ticket_id" value="@ticket_id@">
	  <input type="hidden" name="return_url" value="@return_url@">
	  <input type="submit" value="#intranet-core.Edit#" name=submit3>
        </form>
      </td>
    </tr>
  </if>
</table>