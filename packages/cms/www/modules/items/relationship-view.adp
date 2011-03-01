<master src="../../master">
<property name="title">Relationship Details</property>

<h3>Relationship Details</h3>

<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">

<tr bgcolor="#FFFFFF">

  <td align=left><b>Attributes</b></td>

  <td align=center>Relationship between 
     <a href="index?item_id=@rel_info.item_id@&mount_point=$mount_point">
       @rel_info.item_title@
     </a>
     and
     <if @rel_info.is_item@ eq t>
       <a href="index?item_id=@rel_info.related_object_id@&mount_point=$mount_point">
         @rel_info.related_title@
       </a>     
     </if>
     <else>@rel_info.related_title@</else>
  </td>
  
  <td align=right><a href="unrelate-item?rel_id=@rel_id@&mount_point=@mount_point@">
        <img src="../../resources/Delete16.gif" border=0></a></td>

</tr>

<tr>

<td colspan=3>

<table bgcolor=#6699CC cellspacing=0 cellpadding=2 border=0 width="100%">

  <tr bgcolor="#FFFFFF">
    <td>Relation Tag</td>
    <td>&nbsp;&nbsp;&nbsp;</td>
    <td>@rel_info.relation_tag@</td>
  </tr>

  <tr bgcolor="#EEEEEE">
    <td>Sort Order </td>
    <td>&nbsp;&nbsp;&nbsp;</td>
    <td>@rel_info.order_n@</td>
  </tr>

  <multiple name=rel_attrs>

    <tr bgcolor="#99CCFF">
      <th colspan=3 align=left nowrap>@rel_attrs.type_name@</th>
    </tr>

    <group column=type_name>
      <if @rel_attrs.groupnum@ odd><tr bgcolor="#FFFFFF"></if>
      <else><tr bgcolor="#EEEEEE"></else>
          <td>@rel_attrs.attribute_label@</td>
          <td>&nbsp;&nbsp;&nbsp;</td>
          <td><if @rel_attrs.value@ nil>&nbsp;</if>
              <else>@rel_attrs.value@</else></td>
     </tr>
   </group>

</multiple>

</table>

</td></tr>

</table>


