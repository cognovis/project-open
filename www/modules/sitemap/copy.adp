<master src="../../master">

<if @no_items_on_clipboard@ eq "t">
<property name="title">Copy Items</property>
<h2>Copy Items to:</h2>
  <p>No items are currently available for copying. Please mark
     your choices and return to this form.</p>
</if>
<else>
<property name="title">Copy Items to @path;noquote@</property>
<h2>Copy Items to @path@</h2>
<formtemplate id="copy">
<formwidget id="id">

<p>  
  <formerror id=copied_items>
    <font color=red>Please choose at least one item to copy</font>
  </formerror>
</p>

<table bgcolor=#6699CC cellspacing=0 cellpadding=4 border=0 width="95%">

<tr>
<td>

<table bgcolor=#99CCFF cellspacing=0 cellpadding=2 border=0 width="100%">

  <tr><td>&nbsp;</td>
      <th align=left>Name</th>
      <th align=left>Title</th>

  <multiple name=marked_items>

  <if @marked_items.rownum@ odd><tr bgcolor=white></if>
  <else><tr bgcolor=#eeeeee></else>

  <td>
    <input name=copied_items type=checkbox value=@marked_items.item_id@>
    <formwidget id="parent_id_@marked_items.item_id@">
  </td>

  <td>
    @marked_items.name@
  </td>

  <td>
    @marked_items.title@
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
