<master>

<br>
<table>
<tr>
<td>
<h1>@page_title@</h1>
</td>
<td>
	<p>
	The ASUS (Automatic Software Update Service) allows you to
	update system components in a semiautomatic way.
	Please see <a href="user-agreement">terms and conditions</a>.
	</p>
	<p>
	You will need to go through the following steps in order to
	setup your ASUS account:
	<ol>
	<li>Create an account for yourself (email).
	<li>Register this system as your @po;noquote@ server.
	<li>Create a company for yourself.
	</ol>
	</p>
</td>
</tr>
</table>

<table>
<th>
<tr class=rowtitle>
<td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.User_Account "Category"] %></td>
<td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.User_Account "Value"] %></td>
<td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.User_Account "Status"] %></td>
<td class=rowtitle><%= [lang::message::lookup "" intranet-security-update-client.User_Account "Action"] %></td>
</tr>
</th>

<if "unknown" eq @user_account_status@>
<tr>
<td><%= [lang::message::lookup "" intranet-security-update-client.Your_Email "Your<br>Email"] %></td>
<td>@email@</td>
<td>@user_account_status@</td>
<td><a class="button" href="@create_account_url;noquote@">Create User Account</a>
</tr>
</if>

<if "exists" eq @user_account_status@>
<tr>
<td><%= [lang::message::lookup "" intranet-security-update-client.Your_Email "Your<br>Email"] %></td>
<td>@email@</td>
<td>@user_account_status@</td>
<td>
	Password<br>
	<form action="@login_url;noquote@" method=GET>
	<input type=hidden name=email value="@email;noquote@">
	<input type=password name=password value="">
	<input type=submit value="Login">
	</form>
</td>
</tr>
</if>



<tr>
<td><%= [lang::message::lookup "" intranet-security-update-client.Your_System "Your<br>SystemID"] %></td>
<td>@system_id@</td>
<td>@system_status@</td>
<td><a class="button" href="@create_system_url;noquote@">Create System</a></td>
</tr>

<tr>
<td><%= [lang::message::lookup "" intranet-security-update-client.Your_Company "Your<br>Company"] %></td>
<td>@company_name@</td>
<td>@company_status@</td>
<td><a class="button" href="">Create Company</a>
</tr>

<tr>
<td><%= [lang::message::lookup "" intranet-security-update-client.Your_Company "Your<br>Contract"] %></td>
<td>@contract_end_date@</td>
<td>@company_status@</td>
<td><a class="button" href="">Create Contract</a></td>
</tr>


</table>

