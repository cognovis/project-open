<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">#intranet-cost.finance#</property>

<br>
<%= [im_costs_navbar "none" "/intranet/invoices/index" "" "" [list] "costs_home"] %>

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    <H2>@page_title;noquote@</H2>

    #intranet-cost.lt_This_is_the_homepage_#

    <h5>#intranet-cost.Documentation#</h5>
    <ul>
	<li><a href="http://www.project-open.com/">#intranet-cost.lt_Finance_high-level_de#</a>
    </ul>


    <h5>#intranet-cost.Options#</h5>
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


