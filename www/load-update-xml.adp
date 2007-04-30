<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>


<h1>@page_title@</h1>

<form action="load-update-xml-2" method=POST>
<table>
<tr>
  <td>Update URL:</td>
  <td><input name=service_url size=60 value="@update_url;noquote@"></td>
</tr>
<tr>
  <td>Service<br>Email:</td>
  <td><input name=service_email size=40 value="@user_email;noquote@"></td>
</tr>
<tr>
  <td>Service<br>Password:</td>
  <td>
    <input type=password name=service_password size=40 value=""><br>
    <small>Attention! This is <strong>not</strong> the login password for you local server.</small>
  </td>
  <td>
  </td>
</tr>
<tr>
  <td colspan=2 align=right>
    <input type=submit name=check value="Check for Updates">
  </td>
</tr>
</table>
</form>

<h2>How to get the Automatic Software Update Service?</h2>

<p>
The <span class=brandsec>]</span><span class=brandfirst>project-open</span><span class=brandsec>[</span>
Automatic Software Update service is not free.<br>
Please read the
<a href="http://www.project-open.com/en/services/">
service description</a> and 
<a href="http://www.project-open.com/contact/">contact us</a>
in order to get access <br>
to the service.
</p>
