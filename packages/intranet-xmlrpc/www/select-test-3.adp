<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">admin</property>

<h1>@page_title@</h1>

<if "ok" eq @status@>

	<form action="select-test-4" method=POST>
	<%= [export_form_vars url token timestamp user_id object_type] %>
	<table cellpadding=2 cellspacing=0 border=0>
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
	
	<tr class=roweven>
	  <td valign=top>Object Type:</td>
	  <td><input type=text name=object_type value="@object_type@" size=20 disabled></td>
	</tr>
	
	<tr class=rowodd>
	  <td valign=top>Object ID:</td>
	  <td>
	    <select name=object_id>
	    @object_id_options;noquote@
	    </select>
	  </td>
	</tr>
	<tr>
	  <td></td>
	  <td><input type=submit></td>
	</tr>
	</table>
	</form>

</if>
<else>

	<ul>
	<li>Error: @error@
	<li>Message:<br><pre>@error_msg@</pre>
   	</ul>

</else>

