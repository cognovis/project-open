<html>

<head>

<title>Template Properties</title>

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

<!-- begin folder -->

<tr bgcolor=#DDDDDD>
<td>
<table cellpadding=2 cellspacing=0 border=0>
<tr>

  <th nowrap align=left>&nbsp;Template:</th>
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

<tr><td bgcolor=#FFFFFF>&nbsp;</td></tr>

<tr><td bgcolor=#FFFFFF>
<!-- begin tabs -->

<table cellpadding=0 cellspacing=0 border=0 bgcolor=#FFFFFF width="100%">
<tr>
<td bgcolor=#FFFFFF>&nbsp;&nbsp;</td>
<td>
<table cellpadding=0 cellspacing=0 border=0 bgcolor=#DDDDDD>

<tr>
<td height=1 colspan=@tab_count@ bgcolor=#999999><img src="assets/gray-dot.gif"
    height=1 width=1></td>
</tr>

<tr align=center>
<td><img src="assets/toolbar-separator.gif"></td>

<multiple name=tabs>
<if @tab@ ne @tabs.name@>
<td>&nbsp;<a 
  href="properties?id=@id@&tab=@tabs.name@">@tabs.label@</a>&nbsp;</td>
</if>
<else>
<td bgcolor=#FFFFFF>&nbsp;<b>@tabs.label@</b>&nbsp;</td>
</else>

<td><img src="assets/toolbar-separator.gif"></td>
</multiple>

</tr>

</table>

<table cellpadding=0 cellspacing=0 border=0 bgcolor=#999999 width="100%">
<tr>
<td height=1 bgcolor=#999999><img src="assets/gray-dot.gif" 
  height=1 width=1></td>
</tr>
</table>

</td>
<td bgcolor=#FFFFFF>&nbsp;&nbsp;</td>
</tr>

<tr>
<td colspan=3 bgcolor=#FFFFFF>&nbsp;&nbsp;</td>
</tr>

<tr>
<td bgcolor=#FFFFFF>&nbsp;&nbsp;</td>
<td bgcolor=#FFFFFF>

  <include src=@tab;noquote@ template_id=@id;noquote@>

</td>
<td bgcolor=#FFFFFF>&nbsp;&nbsp;</td>
</tr>
</table>

<!-- end tabbed pane -->

</td></tr>

<tr><td bgcolor=#FFFFFF>&nbsp;</td></tr>

<tr><td nowrap height=2 bgcolor="#999999"><img src="assets/gray-dot.gif" height=2 width=1></td></tr>

</table>

</td>
</tr>
</table>

</body>
</html>
