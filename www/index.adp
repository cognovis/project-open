<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>

<br>
<%= [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list] "costs_home"] %>

<H2>@page_title;noquote@</H2>
<p>
#intranet-cost.lt_This_is_the_homepage_#
</p>

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    <h3>#intranet-cost.Documentation#</h3>
    <ul>
	<li><a href="http://www.project-open.com/">#intranet-cost.lt_Finance_high-level_de#</a>
    </ul>


    <h3>#intranet-cost.Options#</h3>
    <ul>
	@new_list_html;noquote@
    </ul>

    <%= [im_component_bay left] %>
  </td>
  <td valign=top>


    <h3>#intranet-cost.New_Customer_Docs#</h3>
    @customers_menu;noquote@

    <h3>#intranet-cost.New_Provider_Docs#</h3>
    @provider_menu;noquote@

    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>


