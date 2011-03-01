<html>

<head>

<title>Copy Templates</title>

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
<td align=left>
<table cellpadding=2 cellspacing=0 border=0>
<tr>

  <th nowrap align=left>&nbsp;Copy Templates</th>

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
<tr><td align=left>

<include src=clipboard folder_id=@folder_id;noquote@ action=copy submit=Copy
         prompt="Check the items you wish to copy to the current folder.">

</td></tr>

<!-- end listing -->

</table>

</td>
</tr>
</table>

</body>
</html>

