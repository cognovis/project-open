<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<H2>@page_title;noquote@</H2>
<p>
#intranet-cost.lt_This_is_the_homepage_#
</p>

<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>

    <%= [im_box_header [_ intranet-cost.Documentation]] %>
    <ul>
	<li><a href="http://www.project-open.com/">#intranet-cost.lt_Finance_high-level_de#</a></li>
    </ul>
    <%= [im_box_footer] %>


    <%= [im_box_header [_ intranet-cost.Options]] %>
    <ul>
	@new_list_html;noquote@
    </ul>
    <%= [im_box_footer] %>

    <%= [im_component_bay left] %>
  </td>
  <td valign=top>


    <%= [im_box_header [_ intranet-cost.New_Customer_Docs]] %>
    @customers_menu;noquote@
    <%= [im_box_footer] %>

    <%= [im_box_header [_ intranet-cost.New_Provider_Docs]] %>
    @provider_menu;noquote@
    <%= [im_box_footer] %>

    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>


