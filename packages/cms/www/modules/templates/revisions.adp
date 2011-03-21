<table cellpadding=0 cellspacing=0 border=1 width=100% bgcolor=#ffffff>
<tr><td>

<table cellpadding=2 cellspacing=0 border=0 width=100% bgcolor=#ffffff>
<tr bgcolor=#99CCFF>

      <td align=right>#</td><td>&nbsp;&nbsp;</td>
      <td align=right>Size</td><td>&nbsp;&nbsp;</td>
      <td align=left>Modified</td><td>&nbsp;&nbsp;</td>
      <td align=left>Author</td><td>&nbsp;&nbsp;</td>
      <td align=left>Comment</td><td>&nbsp;&nbsp;</td>
      <td align=left>Publish</td><td>&nbsp;&nbsp;</td>
      <td align=left>Revert</td><td>&nbsp;&nbsp;</td>

</tr>  

<multiple name="revisions">
<if @revisions.revision_id@ eq @live_revision@>
    <tr bgcolor=#FFFFCC>
</if>
<else>
    <tr>
</else>
      <td nowrap align=right>@revisions.revision_number@</td><td>&nbsp;</td>
      <td nowrap align=right>@revisions.file_size@</td><td>&nbsp;</td>
      <td nowrap align=left>@revisions.modified@</td><td>&nbsp;</td>
      <td nowrap align=left>@revisions.modified_by@</td><td>&nbsp;</td>
      <td align=left>@revisions.msg@</td><td>&nbsp;</td>
      <td nowrap align=center><a href="publish?revision_id=@revisions.revision_id@"><img src="assets/Export16.gif" border=0 height=16 width=16></a></td><td>&nbsp;</td>
<if @revisions.revision_number@ ne @revision_count@>
      <td nowrap align=center><a href="edit?template_id=@template_id@&edit_revision=@revisions.revision_id@"><img src="assets/Undo16.gif" border=0 height=16 width=16></a></td>
</if>
<else>
     <td>&nbsp;</td>
</else>
    </tr>
</multiple>

</table>

</td></tr>
</table>