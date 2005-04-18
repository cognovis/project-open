<table cellpadding=2 cellspacing=0 border=0 width=100% bgcolor=#ffffff>

<tr><td colspan=3 nowrap height=3 bgcolor="#FFFFFF"><img src="assets/white-dot.gif" height=3 width=1></td></tr>

<if @template_count@ gt 0>

<tr><td>&nbsp;&nbsp;</td><td>@prompt@</td><td>&nbsp;&nbsp;</td></tr>

<form action="@action@" method=post>
<input type=hidden name=return_url value=@return_url@>
<input type=hidden name=folder_id value=@folder_id@>
<multiple name="templates">
  <tr><td>&nbsp;&nbsp;</td>
    <td nowrap align=left>&nbsp;<input type=checkbox name=template_id value=@templates.template_id@>&nbsp;@templates.path@</td>
  <td>&nbsp;&nbsp;</td></tr>
</multiple>

<tr><td colspan=3 nowrap height=3 bgcolor="#FFFFFF"><img src="assets/white-dot.gif" height=3 width=1></td></tr>

  <tr align=center bgcolor=#FFFFFF>
    <td colspan=3><input type=submit name=submit value=@submit@>&nbsp;
                  <input type=submit name=submit value=Cancel>
    </td>
  </tr>
</form>

</if>
<else>

<tr><td>&nbsp;&nbsp;</td><td>No templates are currently on the
clipboard.  Please mark one or more templates and try
again.</td><td>&nbsp;&nbsp;</td></tr>

<tr><td nowrap height=3 bgcolor="#FFFFFF"><img
src="assets/white-dot.gif" height=3 width=1></td></tr>

<tr><form action="move">
<input type=hidden name=return_url value=@return_url@>
<input type=hidden name=folder_id value=@folder_id@>
  <tr align=center bgcolor=#FFFFFF>
    <td colspan=3><input type=submit name=submit value=OK>
    </td>
  </tr>

</form></tr>

</else>

<tr><td colspan=3 nowrap height=3 bgcolor="#FFFFFF"><img src="assets/white-dot.gif" height=3 width=1></td></tr>

</table>
