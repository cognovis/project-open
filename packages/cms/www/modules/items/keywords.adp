<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">

<tr bgcolor="#FFFFFF">

<td align=left><b>Subject Keywords</b></td>
<td align=right>
  <if @user_permissions.cm_write@ eq t>
    [<a href="../categories/keyword-assign?item_id=@item_id@&mount_point=@mount_point@">
     Assign</a> ] marked keywords to this item
  </if><else>&nbsp;</else>
</td>
</tr>

<tr>

<td colspan=2>

<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">

  <tr bgcolor="#99CCFF">
    <if @keywords:rowcount@ eq 0>
      <td colspan=3><em>No keywords.</em></td></if>
    <else>
      <th align=left nowrap>Heading</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th align=left nowrap>Description</th>
      <td>&nbsp;&nbsp;&nbsp;</td>
      <th>&nbsp</th>
    </else> 
  </tr>

        <multiple name=keywords>
          <if @keywords.rownum@ odd><tr bgcolor="#ffffff"></if>
          <else><tr bgcolor="#cccccc"></else>
            <td><a href="../categories/index?id=@keywords.keyword_id@&mount_point=categories">
                  @keywords.heading@</a></td>
            <td>&nbsp;&nbsp;&nbsp;</td>
            <td>@keywords.description@</td>
            <td>&nbsp;&nbsp;&nbsp;</td>
            <td>
              <if @user_permissions.cm_write@ eq t>
                <a href="../categories/keyword-unassign?item_id=@item_id@&keyword_id=@keywords.keyword_id@&mount_point=@mount_point@">
                  <img src="../../resources/Delete16.gif" border=0></a>
              </if><else>&nbsp;</else>
            </td>
          </tr>
        </multiple>

</table>

</td></tr>

</table>


