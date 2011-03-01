<master src="../../master">
<property name="title">Symlink Items</property>
<h2>Symlink Items</h2>


<if @no_items_on_clipboard@ eq "t">
  <p>No items are currently available for linking. Please mark
     your choices and return to this form.</p>
</if>
<else>
<formtemplate id="symlink">
<formwidget id="id">

<p>  
  <formerror id=symlinked_items>
    <font color=red>Please choose at least one item to symlink</font>
  </formerror>
</p>

<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">

<tr>
<td>

<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">

  <tr><td>&nbsp;</td>
      <th align=left>Target</th>
      <th align=left>Symlink Name</th>
      <th align=left>Symlink Label</th></tr>

  <multiple name=marked_items>

  <if @marked_items.rownum@ odd><tr bgcolor=white></if>
  <else><tr bgcolor=#eeeeee></else>

  <td>
    <input name=symlinked_items type=checkbox value=@marked_items.item_id@>
  </td>

  <td>
    @marked_items.title@
  </td>

  <td>
    <formwidget id="name_@marked_items.item_id@">
  </td>
   
  <td>
    <formwidget id="title_@marked_items.item_id@">
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

