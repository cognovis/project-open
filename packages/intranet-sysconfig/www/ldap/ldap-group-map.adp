<master src="master">
<property name="title">@page_title;noquote@</property>
<property name="enable_prev_p">1</property>
<property name="enable_test_p">0</property>
<property name="enable_next_p">1</property>

<h2>@page_title;noquote@</h2>
<p>
This screen allows you to map your LDAP groups to ]project-open[.<br>
Please select for every LDAP group the corresponding ]po[ "profile".<br>
</p>

<input type=hidden name=ip_address value="@ip_address;noquote@">
<input type=hidden name=port value="@port;noquote@">
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
@groups_select_html;noquote@
</table>
