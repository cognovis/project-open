<html>
  <style>
     body { 
       font-family: Helvetica,sans-serif;
       background-color: white
     }
     td { 
       font-family: Helvetica,sans-serif
     }
     A:link, A:visited, A:active { text-decoration: none }
  </style>
  <script language=Javascript src="modules/clipboard/clipboard.js"></script>
<body>

<h2>Error</h2>

<form name=error_ok method=post action="@return_url@">
<multiple name=vars>
  <input type=hidden name="@vars.name@" value="@vars.value@">
</multiple>

<table border=0 cellpadding=4 cellspacing=0>
<tr><td>
<img src="resources/Stop24.gif"> @message@
</td></tr>
<tr><td align=center>
<input type=submit name=submit value="Ok">
</td></tr>
</table>
</form>

</body>
</html>


