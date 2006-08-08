<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>

<h1>@page_title@</h1>

<p>
This form has already been set to a testing user.<br>
You just need to press Submit:
<ul>
<li>URL:<br>
    Please use "http://172.26.0.3:30038/RPC2" to connect<br>
    to our internal test server or choose your own XML-RPC server.
</li>
<li>Email: <br>
    "ssales@tigerpond.com"</li>
<li>Timestamp: <br>
    "" (leave empty for perpetual)</li>
<li>Passwd: <br>
    "sally"</li>
</ul>
<br>
</p>

<form action="login-test-2" method=POST>
<table cellpadding=1 cellspacing=0 border=0>
<tr>
  <td valign=top>URL:</td>
  <td><input type=text name=url value="http://172.26.0.3:30038/RPC2" size=30></td>
</tr>
<tr>
  <td valign=top>Email:</td>
  <td><input type=text name=email value="ssales@tigerpond.com" size=30></td>
</tr>
<tr>
  <td valign=top>Timestamp:</td>
  <td><input type=text name=timestamp value="" size=30></td>
</tr>
<tr>
  <td valign=top>Password:</td>
  <td><input type=password name=pass value="sally" size=30></td>
</tr>
<tr>
  <td></td>
  <td><input type=submit></td>
</tr>
</table>
</form>
