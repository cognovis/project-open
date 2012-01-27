<master src="master">
<property name="title">@page_title@</property>
<property name="enable_prev_p">1</property>
<property name="enable_test_p">0</property>
<property name="enable_next_p">1</property>

<h2>@page_title@</h2>

<p>
<if @create_p@>
We have successfully created your new LDAP authority <br>
named '@authority_name@'.
</if>
<else>
We have successfully updated your existing LDAP authority <br>
named '@authority_name@'.
</else>
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


<h2>Finish Configuration Process</h2>
<p>
You can finish your configuration process here.<br>
Additional options:
</p>
<ul>
<li><a href="/acs-admin/auth/authority?authority_id=@auth_id@">See your new authority</a>.
<li><a href="/acs-admin/auth/">See the list of authorities</a>.
<li><a href="/register/logout">Logout</a> so that you test the new login screen.
<li><a href="/intranet-sysconfig/ldap/index">Configure a new LDAP driver</a>.
<li><a href="/">Go to the home page</a>.
</ul>

<h2>Import LDAP Objects</h2>
<p>
Please press "Next" below to continue with importing LDAP objects.
</p>

