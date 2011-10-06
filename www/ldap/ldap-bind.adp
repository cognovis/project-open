<master src="master">
<property name="title">@page_title@</property>
<property name="enable_prev_p">@enable_prev_p@</property>
<property name="enable_test_p">@enable_test_p@</property>
<property name="enable_next_p">@enable_next_p@</property>

<h2>@page_title@</h2>

<input type=hidden name=ip_address value="@ip_address;noquote@">
<input type=hidden name=port value="@port;noquote@">
<input type=hidden name=ldap_type value="@ldap_type;noquote@">
<input type=hidden name=domain value="@domain;noquote@">
<input type=hidden name=authority_id value="@authority_id@">
<input type=hidden name=authority_name value="@authority_name@">
<input type=hidden name=group_map value="@group_map;noquote@">

<table>
<tr>
<td>IP/Host:</td>
<td>@ip_address@</td>
</tr>
<tr>
<td>Port:</td>
<td>@port@</td>
</tr>
<tr>
<td>Type:</td>
<td>
	<if "ad" eq @ldap_type@>Microsoft Active Directory</if>
	<else>OpenLDAP</else>
</td>
</tr>
<tr>
<td>Domain:</td>
<td>@domain@</td>
</tr>
<tr>
<td>BindDN<br>(username):</td>
<td><input type=text name=system_binddn size=50 value='@system_binddn;noquote@'></td>
</tr>
<tr>
<td>BindPassword:</td>
<td><input type=text name=system_bindpw size=20 value='@system_bindpw;noquote@'></td>
</tr>
</table>

<if "" ne @debug@>
<h2>Server Message</h2>
<br>
<pre>
@debug@
</pre>
</if>

