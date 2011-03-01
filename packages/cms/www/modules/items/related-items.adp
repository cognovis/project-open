<master src="../../master">
<property name="title">Related Items</property>


<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">

<tr bgcolor="#FFFFFF">

<td align=left><b>Related Items</b></td>
<td align=right>
  <if @user_permissions.cm_relate@ eq t>
    [<a href="relate-items?item_id=@item_id@">Add</a>]
  </if><else>&nbsp;</else>
</td>
</tr>

<tr>

<td colspan=2>

<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">

  <tr bgcolor="#99CCFF">
    <if @related:rowcount@ eq 0>
      <td colspan=2><em>No related items.</em></td></if>
    <else>
      <th>&nbsp;</th>
      <td>&nbsp;&nbsp;&nbsp;</td>     
      <th align=left nowrap>Content Type</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th align=left nowrap>Title</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th align=left nowrap>Relationship Type</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th align=left nowrap>Tag</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th align=left nowrap>&nbsp;</th>
      <th align=left nowrap>&nbsp;</th>
    </else> 
  </tr>

  <multiple name="related">

    <if @related.rownum@ odd><tr bgcolor="#FFFFFF"></if>
    <else><tr bgcolor="#EEEEEE"></else>

      <td nowrap height=12>
        <include src="../../bookmark" 
                 mount_point="@mount_point;noquote@" 
                 id="@related.item_id;noquote@">
      </td>    
      <td>&nbsp;&nbsp;&nbsp;</td> 
      <td>@related.content_type@</td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td>
	<if @related.title@ nil>&nbsp;</if>
	<else>
          <a href="index?item_id=@related.item_id@">@related.title@</a>
	</else>
      </td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td>@related.type_name@</td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td><a href="relationship-view?rel_id=@related.rel_id@&mount_point=@mount_point@">
            @related.tag@</a></td>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <td nowrap>
        <if @user_permissions.cm_relate@ eq t>
          <a href="unrelate-item?rel_id=@related.rel_id@&mount_point=@mount_point@">
          <img src="../../resources/Delete16.gif" border=0></a>
        </if><else>&nbsp;</else>
      </td>
      <td nowrap>
        <if @user_permissions.cm_relate@ eq t>
          <table border=0 cellspacing=2 cellpadding=0>
             <tr><td><a href="relate-order?rel_id=@related.rel_id@&order=up&mount_point=@mount_point@&relation_type=relation">
                <img src="../../resources/triangle-up.gif" border=0></a></td></tr>
            <tr><td><a href="relate-order?rel_id=@related.rel_id@&order=down&mount_point=@mount_point@&relation_type=relation">
                <img src="../../resources/triangle-dn.gif" border=0></a></td></tr>
          </table>
        </if><else>&nbsp;</else>
      </td>
     </tr>

</multiple>
</table>

</td></tr>
</table>


<script language=JavaScript>
  set_marks('@mount_point@', '../../resources/checked');
</script>
