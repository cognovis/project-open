<master src="../../master">
<property name="title">Child Items</property>

<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">
<tr bgcolor="#FFFFFF">
  <th align=left valign=bottom>Child Items</th>

    <if @user_permissions.cm_relate@ eq t>
      <formtemplate id=add_child>
      <td align=right valign=bottom>
        <formwidget id=parent_id><formwidget id=content_type> 
	<input type=submit value="Add">
      </td>
      </formtemplate>
    </if>
    <else>
      <td>&nbsp;</td>
    </else>
  </td>
</tr>



<tr>
<td colspan=2>

<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">

  <tr bgcolor="#99CCFF">
    <if @children:rowcount@ eq 0>
      <td colspan=3><em>No child items.</em></td></if>
    <else>
      <th>&nbsp;&nbsp;</th>
      <th align=left>Content Type</th>
      <th>&nbsp;&nbsp;</th>
      <th align=left>Title</th>
      <th>&nbsp;&nbsp;</th>
      <th align=left>Relationship Type</th>
      <th>Relation Tag</th>
      <th>&nbsp;</th>
    </else> 
  </tr>

  <multiple name="children">

    <if @children.rownum@ odd><tr bgcolor="#FFFFFF"></if>
    <else><tr bgcolor="#EEEEEE"></else>

      <td height=12>
        <include src="../../bookmark" 
                 mount_point="@mount_point;noquote@" 
                 id="@children.item_id;noquote@">&nbsp;
      </td>

      <td>@children.content_type@</td>
      <td>&nbsp;&nbsp;</td>
      <td><a href="index?item_id=@children.item_id@">
        <if @children.title@ not nil>@children.title@</if>
        <else>-</else></a></td>
      <td>&nbsp;&nbsp;</td>
      <td>@children.type_name@</td>
      <td>@children.tag@</td>

      <td nowrap>
        <if @user_permissions.cm_write@ eq t>
          <table border=0 cellspacing=2 cellpadding=0 width="100%">
             <tr><td><a href="relate-order?rel_id=@children.rel_id@&order=up&mount_point=@mount_point@&relation_type=child">
                <img src="../../resources/triangle-up.gif" border=0></a></td></tr>
             <tr><td><a href="relate-order?rel_id=@children.rel_id@&order=down&mount_point=@mount_point@&relation_type=child">
                <img src="../../resources/triangle-dn.gif" border=0></a></td></tr>
          </table>
        </if>
	<else>&nbsp;</else>
      </td>
     </tr>

</multiple>
</table>

</td></tr>
</table>

<script language=JavaScript>
  set_marks('@mount_point@', '../../resources/checked');
</script>



