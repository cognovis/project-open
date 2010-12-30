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
<p>
</p>
<nobr>
IP/Host: 
<input type=text name=ip_address value="@ip_address@" size=16 maxsize=16>
Port: 
<input type=text name=port value="@port@" size=5 maxsize=5>
</nobr>
<p>
<br>

<pre>
@debug@
</pre>
