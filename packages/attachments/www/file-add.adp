<master>
<property name="title">#attachments.lt_Upload_New_Attachment#</property>
<property name="context">@context;noquote@</property>

<p>#attachments.you_are_attaching_document_to_object#</p>

<form enctype="multipart/form-data" method="POST" action="file-add-2">
<div>
<input type=hidden name="folder_id" value="@folder_id@">
<input type=hidden name="object_id" value="@object_id@">
<input type=hidden name="return_url" value="@return_url@">
</div>

<table border=0>

<tr>
<td align=right>
<label for="upload_file">#attachments.Version_filename_#</label></td>
<td><input type="file" name="upload_file" id="upload_file" size=20></td>
</tr>

<tr>
<td>&nbsp;</td>
<td>#attachments.lt_Use_the_Browse_button#</td>
</tr>

<tr>
<td>&nbsp;</td>
<td>&nbsp;</td>
</tr>

<tr>
  <if @lock_title_p@ eq 0>
    <td align=right><label for="title">#attachments.Title#</label></td>
    <td><input size=30 name="title" id="title" value="@title@"></td>
  </if>
  <else>
      <td align=right> #attachments.Title#
        <input type=hidden name=title value=@title@>
      </td>
      <td>@title@</td>
  </else>
</tr>

<tr>
<td valign=top align=right>
  <label for="description">#attachments.Description#</label>
</td>
<td>
  <textarea rows=5 cols=50 name="description" id="description"></textarea></td>
</tr>

<tr>
<td></td>
<td><input type=submit value="Upload">
</td>
</tr>

</table>
</form>
