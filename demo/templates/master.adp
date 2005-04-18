<html>
  <style>

     .blue { background-color: #99CCFF }
     .large { font-size: large }

     body { 
       font-family: Helvetica,sans-serif;
       background-color: white
     }
     td { 
       font-family: Helvetica,sans-serif;
     }
     th { 
       font-family: Helvetica,sans-serif;
       text-align: left;
     }

     A:link, A:visited, A:active { text-decoration: none }

  </style>
  <head><title>@content.title@</title></head>
<body>

<table width=100% border=0 cellpadding=20>
<tr>
<td bgcolor="#99ccff" width=100>DEMO<br>COMPANY</td>
<td bgcolor="#FFFFCC"> @content.title@</td>
</tr>
</table>
<br>
You are here: 
  <multiple name="folders"><a href="@folders.url@">@folders.title@</a>
  <if @folders.rownum@ lt @folders:rowcount@> : </if>
  </multiple>

<hr>

<blockquote>

@content.text@

<slave>

</blockquote>

<hr>

<em>Copyright &copy; 2000 Demo Corporation All Rights Reserved</em>

</body>
</html>
