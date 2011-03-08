<master src="../../master">
<property name="title">Clipboard</property>

<script language=javascript>

  top.treeFrame.setCurrentFolder('@mount_point@', '@id@', '@parent_id@');

  function mark_and_reload(mount_point, id) {
    mark('@package_url@', mount_point, id, '@clipboardfloats_p@');
    window.location.reload();
  }

</script> 

<tabstrip id=clip_tabs></tabstrip>

<if @id@ nil>
  <h2>Clipboard</h2>

  <if @total_items@ gt 0>
    <p>There are a total of @total_items@ items on the clipboard. Select one of
    the mount points on the left to view a list of clipped items for the
    mount point.</p>

    <p><a href="clear-clipboard">Clear the clipboard</a></p>
 
  </if>
  <else>
    There are no items on the clipboard.
  </else>
  <p><a href="javascript:window.close()">Close the clipboard</a>
</if>
<else>

<h2>Clipped Items</h2>

<if @items:rowcount@ gt 0>

  <table border=0 cellpadding=4 cellspacing=0>

  <multiple name=items>
  <tr>
    <td>
      <a href="javascript:mark_and_reload('@id@', '@items.item_id@')"><img 
	 src="../../resources/Delete24.gif" width=24 height=24 
	 border=0></a>
    </td>
    <td>
      <a href="@items.url@" target=listFrame>@items.item_path@</a>
    </td>
  </tr>
  </multiple>
  </table>
</if>
<else><p><i>No items</i></p></else>

</else>

</body>
</html>
