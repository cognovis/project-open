<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>

<br>
<%= [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list] "invoices_home"] %>

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    <H2>@page_title;noquote@</H2>

    This is the homepage of the "Financial Area". Here you can
    find and enter all information about customers, projects
    and users.<br>
    For more details please see:
    <ul>
	<li><a href="http://www.project-open.com/">Finance high-level description</a>
    </ul>


    <ul>
	@new_list_html;noquote@
    </ul>

    <%= [im_component_bay left] %>
  </td>
  <td valign=top>
    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>

