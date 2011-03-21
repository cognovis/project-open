<html>

<head>

<title>Template Browser</title>

<style>
  body {
    background-color: white
  }
  th { 
    font-size: 9pt;
    font-family: sans-serif;
  }
  td { 
    font-size: 9pt;
    font-family: sans-serif;
  }
</style>

<script language=Javascript src="../clipboard/clipboard.js"></script>

<script language=javascript>
  top.treeFrame.setCurrentFolder('templates', '@refresh_id@', '');
</script> 

<script language=JavaScript>
  function setSrc(name, src) {
    document.images[name].src = "assets/" + src;
  }
</script>
 
</head>

<body>

<table cellpadding=2 cellspacing=0 border=1 width="100%">

<tr bgcolor=#6699CC>
<td>

<table cellpadding=0 cellspacing=0 border=0 width="100%">

<tr><td nowrap height=1 bgcolor="#999999"><img src="assets/gray-dot.gif" height=1 width=1></td></tr>
<tr><td nowrap height=1 bgcolor="#FFFFFF"><img src="assets/white-dot.gif" height=1 width=1></td></tr>

<!-- begin toolbar -->

<tr bgcolor=#DDDDDD>
<td>
<table cellpadding=2 cellspacing=0 border=0>
<tr>

  <td nowrap height=26 width=113><a href="new-template?folder_id=@id@" onMouseOver="setSrc('new-template', 'new-template-over.gif')" onMouseDown="setSrc('new-template', 'new-template-down.gif')" onMouseOut="setSrc('new-template', 'new-template-up.gif')"><img name=new-template src="assets/new-template-up.gif" height=26 width=113 border=0 alt="Create New Template"></a></td>
  <td nowrap height=26 width=98><a href="new-folder?parent_id=@id@" onMouseOver="setSrc('new-folder', 'new-folder-over.gif')" onMouseDown="setSrc('new-folder', 'new-folder-down.gif')" onMouseOut="setSrc('new-folder', 'new-folder-up.gif')"><img name=new-folder src="assets/new-folder-up.gif" height=26 width=98 border=0 alt="Create New Folder"></a></td>
  <td nowrap height=26 width=2><img src="assets/toolbar-separator.gif" height=24 width=2 border=0></td>
  <td nowrap height=26 width=64><a href="move?folder_id=@id@" onMouseOver="setSrc('move', 'move-over.gif')" onMouseDown="setSrc('move', 'move-down.gif')" onMouseOut="setSrc('move', 'move-up.gif')"><img name=move src="assets/move-up.gif" height=26 width=64 border=0 alt="Move Marked Items"></a></td>
  <td nowrap height=26 width=58><a href="copy?folder_id=@id@" onMouseOver="setSrc('copy', 'copy-over.gif')" onMouseDown="setSrc('copy', 'copy-down.gif')" onMouseOut="setSrc('copy', 'copy-up.gif')"><img name=copy src="assets/copy-up.gif" height=26 width=58 border=0 alt="Copy Marked Items"></a></td>
  <td nowrap height=26 width=70><a href="delete?folder_id=@id@" onMouseOver="setSrc('delete', 'delete-over.gif')" onMouseDown="setSrc('delete', 'delete-down.gif')" onMouseOut="setSrc('delete', 'delete-up.gif')"><img name=delete src="assets/delete-up.gif" height=26 width=70 border=0 alt="Delete Marked Items"></a></td>

</tr>
</table>
</td>
</tr>
<!-- end toolbar -->

<tr><td nowrap height=1 bgcolor="#999999"><img src="assets/gray-dot.gif" height=1 width=1></td></tr>
<tr><td nowrap height=1 bgcolor="#FFFFFF"><img src="assets/white-dot.gif" height=1 width=1></td></tr>

<!-- begin folder -->

<tr bgcolor=#DDDDDD>
<td align=left>
<table cellpadding=2 cellspacing=0 border=0>
<tr>

  <th nowrap align=left>&nbsp;Folder:</th>
  <form action="index"><td nowrap><input size=40 name="path" value="@path@"></td></form>

</tr>
</table>
</td>
</tr>

<!-- end folder -->

<tr><td nowrap height=1 bgcolor="#999999"><img src="assets/gray-dot.gif" height=1 width=1></td></tr>
<tr><td nowrap height=1 bgcolor="#FFFFFF"><img src="assets/white-dot.gif" height=1 width=1></td></tr>
<tr><td nowrap height=3 bgcolor="#DDDDDD"><img src="assets/light-gray-dot.gif" height=3 width=1></td></tr>
<tr><td nowrap height=2 bgcolor="#999999"><img src="assets/gray-dot.gif" height=2 width=1></td></tr>

<!-- begin listing -->

<tr>
<td>
<table cellpadding=2 cellspacing=0 border=0 width=100% bgcolor=#ffffff>
<tr bgcolor=#99CCFF>

      <td height=12 width=12 nowrap>Mark</td><td>&nbsp;&nbsp;</td>
      <td>&nbsp;</td><td>&nbsp;&nbsp;</td>
      <td align=left>Name&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;&nbsp;</td><td>&nbsp;&nbsp;</td>
      <td align=right>Size</td><td>&nbsp;&nbsp;</td>
      <td align=left>Modified</td><td>&nbsp;&nbsp;</td>
      <td align=center>Edit</td><td>&nbsp;&nbsp;</td>
      <td align=center>Upload</td>
</tr>  

<if @parent@ not nil>
    <tr>
      <td nowrap height=12>&nbsp;</td><td>&nbsp;</td>
      <td nowrap height=16 width=16><img src="assets/Up16.gif" height=16 width=16 alt="@parent.label@"></td><td>&nbsp;</td>
      <td nowrap align=left><a href="index?id=@parent.folder_id@">@parent.name@</a></td><td>&nbsp;</td>
      <td nowrap align=right>-</td><td>&nbsp;</td>
      <td nowrap align=left>-</td><td>&nbsp;</td>
      <td nowrap align=center>&nbsp;</td>
      <td nowrap align=center>&nbsp;</td>
      <td nowrap align=center>&nbsp;</td>
    </tr>
</if>

<multiple name="folders">
    <tr>
      <td nowrap height=12>&nbsp;<a 
  href="javascript:markx('@package_url@', 'templates', @folders.folder_id@, 
                         'assets/checked', 'assets/unchecked', '@clipboardfloats_p@')"><img 
  src="assets/unchecked.gif" height=12 width=12 border=0
  name="mark@folders.folder_id@"></a></td><td>&nbsp;</td>
      <td nowrap height=16 width=16><img src="assets/folder.gif" height=16 width=16 alt="@folders.label@"></td><td>&nbsp;</td>
      <td nowrap align=left><a href="index?id=@folders.folder_id@">@folders.name@</a></td><td>&nbsp;</td>
      <td nowrap align=right>-</td><td>&nbsp;</td>
      <td nowrap align=left>@folders.modified@</td><td>&nbsp;</td>
      <td nowrap align=center>&nbsp;</td>
      <td nowrap align=center>&nbsp;</td>
      <td nowrap align=center>&nbsp;</td>
    </tr>
</multiple>

<multiple name=items>
    <tr>
      <td nowrap height=12>&nbsp;<a 
  href="javascript:markx('@package_url@', 'templates', @items.template_id@, 
                         'assets/checked', 'assets/unchecked', '@clipboardfloats_p@')"><img 
  src="assets/unchecked.gif" height=12 width=12 border=0
  name="mark@items.template_id@"></a></td><td>&nbsp;</td>
      <td nowrap height=16 width=16><img src="assets/template.gif" height=16 width=16></td><td>&nbsp;</td>
      <td nowrap align=left><a href="properties?id=@items.template_id@">@items.name@</a></td><td>&nbsp;</td>
      <td nowrap align=right>@items.file_size@</td><td>&nbsp;</td>
      <td nowrap align=left>@items.modified@</td><td>&nbsp;</td>
      <td nowrap align=center><a href="edit?template_id=@items.template_id@"><img src="assets/Edit16.gif" border=0 height=16 width=16></a></td><td>&nbsp;</td><td nowrap align=center><a href="upload?template_id=@items.template_id@"><img src="assets/Import16.gif" border=0 height=16 width=16></a></td>
    </tr>
</multiple>

</table>
</td>
</tr>

<!-- end listing -->

<tr><td nowrap height=2 bgcolor="#999999"><img src="assets/gray-dot.gif" height=2 width=1></td></tr>

</table>

</td>
</tr>
</table>

<script language=JavaScript>set_marks('templates', 'assets/checked');</script>

</body>
</html>
