<master>
<property name="title">#attachments.Attach_URL#</property>
<property name="context">@context;noquote@</property>

<p>
#attachments.you_are_attaching_url_to_object#
</p>

<form method=POST action="simple-add-2">
<div>
<input type=hidden name="folder_id" value="@folder_id@">
<input type=hidden name="type" value="@type@">
<input type=hidden name="object_id" value="@object_id@">
<input type=hidden name="return_url" value="@return_url@">
</div>

<table border=0>

<tr>
  <if @lock_title_p@ eq 0>
    <td align=right><label for="title">#attachments.Title#</label></td>
    <td><input size=30 name="title" value="@title@" id="title"></td>
  </if>
  <else>
     <td align=right>#attachments.Title#</td>
     <td>
       @title@
       <input type=hidden name="title" value="@title@">
     </td>
  </else>
</tr>

<tr>
<td align=right><label for="url">#attachments.URL_1#</label></td>
<td><input size=50 name="url" value="http://" id="url"></td>
</tr>

<tr>
<td valign=top align=right><label for="description">#attachments.Description#</label></td>
<td><textarea rows=5 cols=50 name="description" id="description"></textarea></td>
</tr>

<tr>
<td></td>
<td><input type=submit value="Create">
</td>
</tr>

</table>
</form>

