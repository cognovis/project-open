<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">

<tr bgcolor="#FFFFFF">

  <td align=left><b>Attributes</b></td>

  <td align=center>Revision #@info.revision_number@ of @info.revision_count@
  <if @info.live_revision@ eq @revision_id@>
    (<font color=red>Live</font>) 
  </if>&nbsp;
  </td>
  <td align=right>
    <if @user_permissions.cm_write@ eq t>
      [<a href="attributes-edit?item_id=@info.item_id@">Edit</a>]
    </if><else>&nbsp;</else>
  </td>

</tr>

<tr>

<td colspan=3>

<table bgcolor=#6699CC cellspacing=0 cellpadding=2 border=0 width="100%">

  <multiple name=attributes>

    <tr bgcolor="#99CCFF">
      <th colspan=3 align=left nowrap>@attributes.object_label@</th>
    </tr>

    <group column=object_label>
      <if @attributes.groupnum@ odd><tr bgcolor="#FFFFFF"></if>
      <else><tr bgcolor="#EEEEEE"></else>
          <td>@attributes.attribute_label@</td>
          <td>&nbsp;&nbsp;&nbsp;</td>
          <td><if @attributes.attribute_value@ nil or @attributes.attribute_value@ eq " ">&nbsp;</if>
              <else>@attributes.attribute_value@</else></td>
     </tr>
   </group>

</multiple>

</table>

</td></tr>

</table>







