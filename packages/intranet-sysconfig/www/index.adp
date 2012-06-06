<master src="../../intranet-core/www/admin/master">
<property name="title">@page_title;noquote@</property>
<property name="admin_navbar_label">admin_sysconfig</property>


<table>
<tr valign=top>
<td>

	<table cellpadding=0 cellspacing=0 border=0 width=100%>
	<tr>
	  <td valign=top>
	    <H2>@page_title;noquote@</H2>
	    <ul>
		<li><a href="/intranet-sysconfig/segment/index">Basic Configuration Wizard</a><br>&nbsp;
		<li><a href="/intranet-sysconfig/ldap/index">LDAP Configuration Wizard</a><br>&nbsp;
		<li><a href="/intranet-sysconfig/export-conf/index?format=html">Export Configuration (HTML)</a><br>&nbsp;
		<li><a href="/intranet-sysconfig/export-conf/index?format=csv">Export Configuration (CSV)</a><br>&nbsp;
		<li><a href="/intranet-sysconfig/import-conf/index">Import Configuration</a><br>&nbsp;
	    </ul>
	    <h2>Other</h2>
	    <ul>
		<li><a href="/intranet-sysconfig/unconfigure">Disable everything except SysConfig Wizard</a><br>&nbsp;
		<li><a href="/intranet-sysconfig/del_security_tokens">Delete Security Tokens</a><br>&nbsp;
		<li><a href="/intranet-sysconfig/move_projects">Move Projects & Forum Topics</a><br>&nbsp;
	    </ul>
	    <%= [im_component_bay left] %>
	  </td>
	  <td valign=top>
	    <%= [im_component_bay right] %>
	  </td>
	</tr>
	</table><br>

</td>
<td>
	<h2>Available Configuration Templates</h2>
	<listtemplate name="templates"></listtemplate>

</td>
</tr>
</table>


<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>


