<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">nagios</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    <%= [im_box_header [_ intranet-nagios.Nagios]] %>
    <ul>
	<li>
		<a href="<%= [export_vars -base "/shared/parameters" {{package_id $nagios_package_id} return_url}] %>"
		>#intranet-nagios.Nagios_Parameters#</a></li>
	<li>
		<a href="<%= [export_vars -base "/intranet-nagios/import-nagios-confitems" {return_url}] %>"
		>#intranet-nagios.Import_Nagios_Configuration#</a></li>
    </ul>
    <%= [im_box_footer] %>

  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>


