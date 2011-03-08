<master>
<property name="title">Attributes to be set by @transition_name;noquote@</property>
<property name="context">@context;noquote@</property>

<table>
  <tr>
    <td width="10%">&nbsp;</td>
    <td>
      <table cellspacing="0" cellpadding="0" border="0">
	<tr>
	  <td bgcolor="#cccccc">
	    <table width="100%" cellspacing="1" cellpadding="4" border="0">
              <tr bgcolor="#ffffe4">
		<th>No.</th>
		<th>Attribute name</th>
                <th>Datatype</th>
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
		    <td align="right">@attributes.sort_order@.</td>
		    <td>@attributes.pretty_name@</td>
                    <td>@attributes.datatype@</td>
		    <td>
		      <if @attributes.edit_url@ not nil>
			(<a href="@attributes.edit_url@">edit</a>)
		      </if>
		      <if @attributes.delete_url@ not nil>
			(<a href="@attributes.delete_url@">delete</a>)
		      </if>
		      <if @attributes.move_up_url@ not nil>
			(<a href="@attributes.move_up_url@">move up</a>)
		      </if>
		    </td>
		  </tr>
		</multiple>    
              </else>
            </table>
          </td>
        </tr>
      </table>
    </td>
    <td width="10%">&nbsp;</td>
  </tr>

  <if @attributes_not_set:rowcount@ gt 0>
    <tr><td colspan="3">&nbsp;</td></tr>
  
    <tr>
      <td>&nbsp;</td>
      <td colspan="2">
	<form action="@add_url@" method="post">
	@add_export_vars;noquote@
	Set this:
	<select name="attribute_id">
	  <multiple name="attributes_not_set">
	    <option value="@attributes_not_set.attribute_id@">
	      @attributes_not_set.pretty_name@ (@attributes_not_set.datatype@)
	    </option>
	  </multiple>
	</select>
	<input type="submit" value="Add" />
	</form>
      </td>
    </tr>
  </if>    

  <tr><td colspan="3">&nbsp;</td></tr>

  <form action="define" method="post">
  <input type="hidden" name="workflow_key" value="@workflow_key@" />
  <input type="hidden" name="transition_key" value="@transition_key@" />
  <tr bgcolor="#dddddd">
    <td colspan="3" align="right">
      <input type="submit" value="Done" />
    </td>
  </tr>
  </form>
</table>

</master>
