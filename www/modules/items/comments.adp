<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">

<tr bgcolor="#FFFFFF">

<td align=left><b>Comments</b></td>

<td align=right>
  <if @user_permissions.cm_write@ eq t>
    [<a href="comment-add?item_id=@item_id@">Add</a>]
  </if>
  <if @comments:has_more_rows@ not nil>&nbsp;&nbsp;&nbsp;&nbsp;(More...)</if>
</td>
</tr>

<tr>

<td colspan=2>

<table bgcolor=#6699CC cellspacing=0 cellpadding=2 border=0 width="100%">

<tr bgcolor="#99CCFF">
<if @comments:rowcount@ gt 0>
  <th align=left nowrap>By</th><td>&nbsp;&nbsp;</td>
  <th align=left nowrap>Date</th><td>&nbsp;&nbsp;</td>
  <th align=left>Comment</th>
</if>
<else>
  <td colspan=3><em>No comments</em></td>  
</else>
</tr>

<multiple name="comments">

<if @comments.rownum@ odd><tr bgcolor="#FFFFFF"></if>
<else><tr bgcolor="#EEEEEE"></else>

  <td nowrap>
  @comments.person@</td><td>&nbsp;&nbsp;</td>
  <td nowrap>@comments.when@</td><td>&nbsp;&nbsp;</td>
  <td><if @comments.action_pretty@ ne "Comment">
    <font color=red>@comments.action_pretty@</font>. </if>
    @comments.msg@&nbsp;</td>

</tr>

</multiple>

</table>

</td></tr>

</table>



