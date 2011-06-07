<table valign="top" align="center" width="350px">
      <tr>
        <td colspan="2" align="center">
          <h3 class="contact-title">@ticket_id@</h3>
        </td>
      </tr>
  <multiple name=ticket_info>
    <if @ticket_info.heading@ not nil>
      <tr>
        <td colspan="2" align="left">
          <h3 class="contact-title">@ticket_info.heading@</h3>
        </td>
      </tr>
    </if>
    <tr>
      <td align="right" valign="top" class="attribute">@ticket_info.field;noquote@:</td>
      <td align="left" valign="top" class="value">@ticket_info.value;noquote@</td>
    </tr>
  </multiple>    
  <if @write@>
    <tr> 
      <td>&nbsp; </td>
      <td> 
        <form action=/intranet-cognovis/ticket/ticket-ae method=POST>
	  <input type="hidden" name="ticket_id" value="@ticket_id@">
	  <input type="hidden" name="return_url" value="@return_url@">
	  <input type=submit value="#intranet-core.Edit#" name=submit3>
        </form>
      </td>
    </tr>
  </if>
</table>