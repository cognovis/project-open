<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>


<h1>@page_title@</h1>

<form action="@update_server;noquote@/register" method=POST>
<input type=hidden name=return_url value="@update_url;noquote@">

<table>
<tr>
  <td>URL:</td>
  <td>@update_url;noquote@</td>
</tr>
<tr>
  <td>Service<br>Email:</td>
  <td><input name=email size=40 value="@user_email;noquote@"></td>
</tr>
<tr>
  <td colspan=2 align=right>
    <input type=submit name=check value="Check for Updates">
  </td>
</tr>
</table>
</form>

<h2>Do you Have Software Update Contract?</h2>

<p>
This page allows you to check for software updates in order 
to keep your system up to date.
<p>
Please enter your service email above 