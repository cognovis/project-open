<master>
<property name="title">Comment on case @case.object_name;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="focus">comment.msg</property>


<table width="100%" cellspacing="0" cellpadding="0" border="0">
<tr bgcolor="#ccccff"><th>Comment</th></tr>
</table>


<table width="100%" cellspacing="0" cellpadding="0" border="0">
<tr><td bgcolor="#cccccc">

<form action="comment-add-2" method="post" name="comment">
@export_form_vars;noquote@
<table width="100%" cellspacing="1" cellpadding="2" border="0">

<tr valign="middle">
<th bgcolor="#ffffe4" width="20%">Comment</th>
<td bgcolor="#eeeeee"><textarea name="msg" rows="6" cols="60"></textarea></td>
</tr>

<tr>
<th bgcolor="#ffffe4"></th>
<td bgcolor="#eeeeee"><input type="submit" name="action.comment" value="Comment" />
&nbsp;&nbsp;&nbsp;
<input type="submit" name="action.cancel" value="Cancel" />
</td>
</tr>
</form>

</table>
</table>


<p>
<include src="journal" case_id="@case_id;noquote@" comment_link="0">

</master>

