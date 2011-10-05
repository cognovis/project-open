<master src="master">
<property name="title">@page_title@</property>
<property name="enable_prev_p">@enable_prev_p@</property>
<property name="enable_test_p">@enable_test_p@</property>
<property name="enable_next_p">@enable_next_p@</property>

<h2>@page_title@</h2>

<p>
Here are the results of testing if an LDAP server
exists at the specified IP address:

<h2>IP Address of the LDAP Server</h2>

<p>
For repeating the test, please enter the IP address 
and port of your LDAP server below and press "Test Parameters".<br>
</p>
<br>

<input type=hidden name=ldap_type value="@ldap_type;noquote@">
<input type=hidden name=domain value="@domain;noquote@">
<input type=hidden name=binddn value="@binddn;noquote@">
<input type=hidden name=bindpw value="@bindpw;noquote@">
<input type=hidden name=system_binddn value="@system_binddn;noquote@">
<input type=hidden name=system_bindpw value="@system_bindpw;noquote@">
<input type=hidden name=authority_id value="@authority_id@">
<input type=hidden name=authority_name value="@authority_name@">
<input type=hidden name=group_map value="@group_map;noquote@">

<table>
<tr>
<td>IP/Host:</td>
<td><input type=text name=ip_address value="@ip_address@" size=16 maxsize=16></td>
</tr>
<tr>
<td>Port:</td>
<td><input type=text name=port value="@port@" size=5 maxsize=5></td>
</tr>
</table>


<br>
<pre>
@debug@
</pre>
