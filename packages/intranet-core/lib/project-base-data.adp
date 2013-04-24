
<table valign="top" width="100%">
<tbody>
    <multiple name="project_info">
      <if @project_info.heading@ not nil>
	<tr>
	  <td colspan="2" align="left">
	    <h3 class="contact-title">@project_info.heading@</h3>
	  </td>
	</tr>
      </if>
      <tr>
	<td align="right" valign="top" class="attribute" width="20%">@project_info.pretty_name;noquote@:</td>
	<td align="left" valign="top" class="value">@project_info.value;noquote@</td>
      </tr>
    </multiple>
    <if @no_write_p@ nil>
    <tr>
      <td>&nbsp; </td>
      <td>
	<table>
	  <tr>
	    <if @write@ and @edit_project_base_data_p@>
	      <td>
		<form action="/intranet/projects/new" method="POST">
		  <input type="hidden" name="project_id" value="@project_id@" />
		    <input type="hidden" name="return_url" value="@return_url@" />
		      <input type="submit" value="#intranet-core.Edit#" name="submit3" />
		</form>
	      </td>
	    </if>
	    <if @notification_message@ not nil>
	      <td>
               <if @notification_request_id@ ne "">
		<form action="/notifications/request-delete">
		  <input type="hidden" name="request_id" value="@notification_request_id@" />
		  <input type="hidden" name="return_url" value="@notification_return_url@" />
		  <input type="submit" value="@notification_button;noquote@" />
		</form>
               </if>
               <else>
		<form action="/notifications/request-new">
		  <input type="hidden" name="object_id" value="@project_id@" />
		  <input type="hidden" name="type_id" value="@notification_type_id@" />
		  <input type="hidden" name="delivery_method_id" value="@notification_delivery_method_id@" />
		  <input type="hidden" name="interval_id" value="@notification_interval_id@" />
		  <input type="hidden" name="form:id" value="subscribe" />
		  <input type="hidden" name="formbutton:ok" value="OK" />
		  <input type="hidden" name="return_url" value="@notification_return_url@" />
		  <input type="submit" value="@notification_button;noquote@" />
		</form> 
               </else> 
	      </td>
	    </if>
	  </tr>
	</table>
      </td>
    </tr>
  </if>
</tbody>
</table>
