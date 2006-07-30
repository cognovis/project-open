<master src="../../intranet-core/www/admin/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>

<h1>@page_title@</h1>

<table cellpadding=2 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top width="50%">

<if "" eq @token@>

  <p>
  You have to login and obtain a security token before
  you can execute any other XML-RPC calls. <br>
  Please use the same email/password as for manual
  login. Please note that only administrators have the right
  to execute XML-RPC calls on their account.
  </p>

  <ul>
  <li><a href="login-test">Login</a>
  </ul>

</if>
<else>

  <ul>
  <li><a href="select-test">Select</a>
  <li><a href="call-test">Call</a>
  </ul>


</else>


  </td>
  <td width=2>&nbsp;</td>
  <td valign=top width="50%">

  </td>
</tr>

<tr>
  <td colspan=3>

  </td>
</tr>
</table><br>


