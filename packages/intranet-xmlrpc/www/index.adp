<master src="../../intranet-core/www/admin/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>


<table cellpadding=2 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top width="50%">

<if "" eq @token@>

  <h1>You need to Login</h1>


  <p>
  You have to login and obtain a security token before
  you can execute any other XML-RPC calls. <br>
  Please use the same email/password as for manual
  login. Please note that only administrators have the right
  to execute XML-RPC calls on their account.
  </p>

  <ul>
  <li><a href="login-test?@vars@">Login</a>
  </ul>

</if>
<else>

  <h1>Login Information</h1>


	<table>
	<tr class=roweven>
	  <td valign=top>URL:</td>
	  <td>@url@</td>
	</tr>
	<tr class=rowodd>
	  <td valign=top>User ID:</td>
	  <td>@user_id@</td>
	</tr>
	<tr class=roweven>
	  <td valign=top>Timestamp:</td>
	  <td>@timestamp@</td>
	</tr>
	<tr class=rowodd>
	  <td valign=top>Token:</td>
		  <td>@token@</td>
	</tr>
	</table>

  <h1>Available Tests</h1>

  <ul>
  <li><a href="select-test?@vars@">Select Test Wizard</a>
  <li><a href="call-test?@vars@">Call Test Wizard</a>
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


