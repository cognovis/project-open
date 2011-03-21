<master src="../../master">
<property name="title">Delete Items</property>
<h2>Delete Items</h2>


<if @no_items_on_clipboard@ eq "t">
  <p>No items are currently available for deleting.  Please mark
     your choices and return to this form.</p>
</if>
<else>
<formtemplate id="delete">

<p>  
  <formerror id=deleted_items>
    <font color=red>Please choose at least one item to delete</font>
  </formerror>
</p>

<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">

<tr>
<td>

<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">

  <tr><td>&nbsp;</td>
      <th align=left>Title</th>
      <th align=left>Path</th>
      <th align=left>Content Type</th></tr>

  <multiple name=marked_items>

  <if @marked_items.rownum@ odd><tr bgcolor=white></if>
  <else><tr bgcolor=#eeeeee></else>

  <td>
    <input name=deleted_items type=checkbox value=@marked_items.item_id@>
    <formwidget id="is_symlink_@marked_items.item_id@">
    <formwidget id="is_folder_@marked_items.item_id@">
    <formwidget id="is_template_@marked_items.item_id@">
  </td>

  <td>
    @marked_items.title@
  </td>

  <td>
    @marked_items.path@
  </td>

  <td>
    @marked_items.content_type_pretty@
  </td>
   
  </tr>

  </multiple>

</table>

</td></tr>

</table>

<br>

<input type=submit value="Submit">

</formtemplate>
</else>
