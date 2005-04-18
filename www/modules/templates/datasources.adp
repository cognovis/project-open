<if @template_exists@ eq f>
  This template does not exist.
</if>
<else>
<if @code_exists@ eq f or @file_exists@ eq f>
  The code for this template does not exist.
</if>
<else>
<if @datasources:rowcount@ eq 0>
  There are no known data sources in this template.
</if>
<else>


<table cellpadding=0 cellspacing=0 border=1 width=100% bgcolor=#ffffff>
<tr><td>

<table cellpadding=2 cellspacing=0 border=0 width=100% bgcolor=#ffffff>
<tr bgcolor=#99CCFF>
      <td align=right>#</td><td>&nbsp;&nbsp;</td>
      <td align=left>Name</td><td>&nbsp;&nbsp;</td>
      <td align=left>Type</td><td>&nbsp;&nbsp;</td>
      <td align=left>Comments</td><td>&nbsp;&nbsp;</td>
</tr>  

<multiple name="datasources">
  <tr>
    <td nowrap align=right valign=top>@datasources.rownum@</td><td>&nbsp;</td>
    <td nowrap align=left valign=top>@datasources.name@</td><td>&nbsp;</td>
    <td nowrap align=left valign=top>@datasources.structure@</td><td>&nbsp;</td>
    <td align=left>

      <if @datasources.is_auto@ nil>@datasources.comment@</if>
      <else><font color=gray>@datasources.comment@</font></else>

      <if @datasources.structure@ in multirow multilist form>
        <if  @datasources.column_name@ ne "-">
	  <br>
	  <table cellpadding=3 cellspacing=0 border=0 width="95%">

	    <if @datasources.structure@ in multirow multilist>
	      <tr>
		<th align=left>Column</th><th align=left>Comment</th>
	      </tr>
	      <group column="name">
		<tr>
		  <td align=left valign=top>@datasources.column_name@</td>
		  <td align=left>@datasources.column_comment@</td>
		</tr>
	      </group>
	    </if>
	    <else>
	      <tr>
		<th align=left>Name</th>
		<th align=left>Type</th>
		<th align=left>Comment</th>
	      </tr>
	      <group column="name">
		<tr>
		  <td align=left>@datasources.input_name@</td>
		  <td align=left>@datasources.input_type@</td>
		  <td align=left>@datasources.input_comment@</td>
		</tr>
	      </group>
	    </else>
	  </table>
	</if>
      </if>
    </td>     
    <td>&nbsp;</td>
  </tr>
</multiple>

</table>

</td></tr>
</table>
</else>
</else>
</else>
