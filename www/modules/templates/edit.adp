<html>

<head>

<title>Edit Template</title>

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
  <table cellpadding=2 cellspacing=0 border=0>
  <tr>

      <th nowrap align=left>Edit Template:</th>
      <td>&nbsp;</td>
      <td nowrap align=left>@path;noquote@</td>

  </tr>
  </table>
</td>
</tr>

<!-- end folder -->

<tr><td nowrap height=1 bgcolor="#999999"><img src="assets/gray-dot.gif" height=1 width=1></td></tr>
<tr><td nowrap height=1 bgcolor="#FFFFFF"><img src="assets/white-dot.gif" height=1 width=1></td></tr>
<tr><td nowrap height=3 bgcolor="#DDDDDD"><img src="assets/light-gray-dot.gif" height=3 width=1></td></tr>
<tr><td nowrap height=2 bgcolor="#999999"><img src="assets/gray-dot.gif" height=2 width=1></td></tr>
<tr><td nowrap height=3 bgcolor="#DDDDDD"><img src="assets/light-gray-dot.gif" height=3 width=1></td></tr>

<formtemplate id="edit_template">
<formwidget id=template_id>
<formwidget id=revision_id>
<tr bgcolor=#DDDDDD align=center><td nowrap>&nbsp;<formwidget id=content>&nbsp;</td></tr>
<tr><td nowrap height=3 bgcolor="#DDDDDD"><img src="assets/light-gray-dot.gif" height=3 width=1></td></tr>
<tr><td nowrap height=3 bgcolor="#DDDDDD"><img src="assets/light-gray-dot.gif" height=3 width=1></td></tr>
<tr><td bgcolor=#DDDDDD nowrap>&nbsp;&nbsp;Output Type: 
<formwidget id="mime_type">
</td></tr>
<tr><td bgcolor=#DDDDDD nowrap>&nbsp;&nbsp;Create new revision: 
<formgroup id="is_update">
  @formgroup.widget;noquote@ @formgroup.label;noquote@
</formgroup>
</td></tr>
<tr bgcolor=#DDDDDD align=center><td nowrap>
<input type=submit name=action value="Save">&nbsp;&nbsp;
<input type=submit name=action value="Cancel">
</td></tr>
<tr><td nowrap height=3 bgcolor="#DDDDDD"><img src="assets/light-gray-dot.gif" height=3 width=1></td></tr>
</formtemplate>

</table>
</td>
</tr>
</table>

</body>

</html>
