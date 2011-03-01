<if @attributes:rowcount@ eq 0>
  <blockquote>
    <em>No attributes defined</em>
  </blockquote>
</if>
<else>
  <table cellspacing="0" cellpadding="0" border="0">
    <tr>
      <td bgcolor="#cccccc">
	<table width="100%" cellspacing="1" cellpadding="4" border="0">
	  <tr bgcolor="#ffffe4">
	    <th>No.</th>
	    <th>Attribute name</th>
	    <th>Datatype</th>
	    <th>Used</th>
	    <th>Action</th>
	  </tr>
	  <if @attributes:rowcount@ eq 0>
	     <tr bgcolor="#eeeeee">
	       <td colspan="4">
		 <em>No attributes</em>
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
		  <if @attributes.used_p@ eq 1>Yes</if>
		  <else>No</else>
		</td>
		<td>
		  <if @attributes.edit_url@ not nil>
		    (<a href="@attributes.edit_url@">edit</a>)
		  </if>
		  <if @attributes.delete_url@ not nil>
		    (<a href="@attributes.delete_url@">delete</a>)
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

(<a href="@add_url@">add attribute</a>)
