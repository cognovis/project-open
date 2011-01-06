<master src="master">
<property name="title">@page_title@</property>
<property name="enable_prev_p">1</property>
<property name="enable_test_p">0</property>
<property name="enable_next_p">1</property>

<h2>@page_title@</h2>

<p>
We have successfully configured your new LDAP authority.
</p>

<input type=hidden name=ip_address value="@ip_address;noquote@">
<input type=hidden name=port value="@port;noquote@">
<input type=hidden name=ldap_type value="@ldap_type;noquote@">
<input type=hidden name=domain value="@domain;noquote@">
<input type=hidden name=binddn value="@binddn;noquote@">
<input type=hidden name=bindpw value="@bindpw;noquote@">
<input type=hidden name=authority_id value="@authority_id@">


<h2>Next Steps</h2>
<ul>
<li>To import users from the new authority.<br>
    Just press on the "Next" button belo.<br>
    &nbsp;
<li><a href="/acs-admin/auth/authority?authority_id=@authority_id@">See your new authority</a>.
<li><a href="/acs-admin/auth/">See the list of authorities</a>.
<li><a href="/register/logout">Logout</a> so that you test the new login screen.
<li><a href="/intranet-sysconfig/ldap/index">Configure a new LDAP driver</a>.
<li><a href="/">Go to the home page</a>.
</ul>


