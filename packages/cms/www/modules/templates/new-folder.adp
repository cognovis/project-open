<html>

<head>

<title>New Folder</title>

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
  h1 { 
    font-size: 12pt;
    font-family: sans-serif;
  }
  textarea { 
    font-size: 9pt;
    font-family: monospace;
  }
</style>

<script language=JavaScript>
  function setSrc(name, src) {
    document.images[name].src = "assets/" + src;
  }
</script>
 
</head>

<body>

<table cellpadding=2 cellspacing=0 border=1>
<tr bgcolor=#6699CC>
<td>
<table cellpadding=0 cellspacing=0 border=0 width="100%">

<tr><td nowrap height=1 bgcolor="#999999"><img src="assets/gray-dot.gif" height=1 width=1></td></tr>
<tr><td nowrap height=1 bgcolor="#FFFFFF"><img src="assets/white-dot.gif" height=1 width=1></td></tr>

<tr bgcolor=#DDDDDD>
<td>
  <table cellpadding=2 cellspacing=0 border=0 width="100%">
  <tr>

      <th nowrap align=left>&nbsp;&nbsp;New Folder</th>
      <td>&nbsp;</td>
      <td nowrap align=right><b>Parent Folder:</b> @path@&nbsp;&nbsp;</td>

  </tr>
  </table>
</td>
</tr>

<!-- end folder -->

<tr><td nowrap height=1 bgcolor="#999999"><img src="assets/gray-dot.gif" height=1 width=1></td></tr>
<tr><td nowrap height=1 bgcolor="#FFFFFF"><img src="assets/white-dot.gif" height=1 width=1></td></tr>
<tr><td nowrap height=3 bgcolor="#DDDDDD"><img src="assets/light-gray-dot.gif" height=3 width=1></td></tr>
<tr><td nowrap height=2 bgcolor="#999999"><img src="assets/gray-dot.gif" height=2 width=1></td></tr>
<tr><td nowrap height=20 bgcolor="#DDDDDD"><img src="assets/light-gray-dot.gif" height=20 width=1></td></tr>

<tr><td nowrap bgcolor="#DDDDDD">

<table cellpadding=2 cellspacing=0 border=0 width="100%">

<formtemplate id="new_folder">
<formwidget id=parent_id>
<formwidget id=folder_id>
<formwidget id=return_url>

<tr bgcolor=#DDDDDD align=left>
  <td nowrap>&nbsp;&nbsp;Name:</td>
  <td>&nbsp;&nbsp;</td>
  <td><formwidget id=name>
      <formerror id=name><br>
        <font color="red"><b>@formerror.name@<b></font>
      </formerror>
      &nbsp;&nbsp;
  </td>
</tr>

<tr bgcolor=#DDDDDD align=left>
  <td nowrap>&nbsp;&nbsp;Label:</td>
  <td>&nbsp;&nbsp;</td>
  <td><formwidget id=label>&nbsp;&nbsp;</td></tr>

<tr bgcolor=#DDDDDD align=left>
  <td nowrap>&nbsp;&nbsp;Description:</td>
  <td>&nbsp;&nbsp;</td>
  <td><formwidget id=description>&nbsp;&nbsp;</td></tr>

<tr><td nowrap height=10 bgcolor="#DDDDDD"><img src="assets/light-gray-dot.gif" height=10 width=1></td></tr>

<tr bgcolor=#DDDDDD align=center><td nowrap colspan=3>
<input type=submit name=action value="Create">&nbsp;&nbsp;
<input type=submit name=action value="Cancel">
</td></tr>
<tr><td nowrap height=10 bgcolor="#DDDDDD"><img src="assets/light-gray-dot.gif" height=10 width=1></td></tr>
</table>
</formtemplate>
</td>
</tr>

</table>
</td>
</tr>
</table>

</body>

</html>
