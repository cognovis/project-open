<if @attributes:rowcount@ eq 0>
  <blockquote>
    <em>#acs-workflow.lt_No_attributes_defined#</em>
  </blockquote>
</if>
<else>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
	<table width="100%" cellspacing="1" cellpadding="4" border="0">
	  <tr bgcolor="#ffffe4">
	    <th>#acs-workflow.No#</th>
	    <th>#acs-workflow.Attribute_name#</th>
	    <th>#acs-workflow.Datatype#</th>
	    <th>#acs-workflow.Used#</th>
	    <th>#acs-workflow.Action#</th>
	  </tr>
	  <if @attributes:rowcount@ eq 0>
	     <tr bgcolor="#eeeeee">
	       <td colspan="4">
		 <em>#acs-workflow.No_attributes#</em>
	       </td>
	     </tr>
	  </if>
	  <else>
	    <multiple name="attributes">
	      <tr bgcolor="#eeeeee">
		<td align="right">@attributes.rownum@.</td>
		<td>@attributes.pretty_name@</td>
		<td>@attributes.datatype@</td>
		<td>
		  <if @attributes.used_p@ eq 1>#acs-workflow.Yes#</if>
		  <else>#acs-workflow.No_1#</else>
		</td>
		<td>
		  <if @attributes.edit_url@ not nil>
		    (<a href="@attributes.edit_url@">#acs-workflow.edit#</a>)
		  </if>
		  <if @attributes.delete_url@ not nil>
		    (<a href="@attributes.delete_url@">#acs-workflow.delete#</a>)
		  </if>
		</td>
	      </tr>
	    </multiple>    
	  </else>
	</table>
      </td>
    </tr>
  </table>
</else>

(<a href="@add_url@">#acs-workflow.add_attribute#</a>)

