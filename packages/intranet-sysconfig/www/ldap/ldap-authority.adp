<master src="master">
<property name="title">@page_title@</property>
<property name="enable_prev_p">1</property>
<property name="enable_test_p">0</property>
<property name="enable_next_p">1</property>

<h2>@page_title@</h2>

<input type=hidden name=ip_address value="@ip_address;noquote@">
<input type=hidden name=port value="@port;noquote@">
<input type=hidden name=ldap_type value="@ldap_type;noquote@">
<input type=hidden name=domain value="@domain;noquote@">
<input type=hidden name=binddn value="@binddn;noquote@">
<input type=hidden name=bindpw value="@bindpw;noquote@">
<input type=hidden name=system_binddn value="@system_binddn;noquote@">
<input type=hidden name=system_bindpw value="@system_bindpw;noquote@">
<input type=hidden name=authority_id value="@authority_id@">
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
<td>SystemBindDN<br>(username):</td>
<td>@system_binddn@</td>
</tr>
<tr>
<td>SystemBindPassword:</td>
<td>@system_bindpw@</td>
</tr>

<tr>
<td>Authority Name:</td>
<td><input type=text name=authority_name value='@authority_name;noquote@' size=30></td>
</tr>

</table>

