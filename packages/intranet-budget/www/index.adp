<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<div id="fullwidth-list" class="fullwidth-list-no-side-bar" style="visibility: visible;">
<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top>
    <%= [im_component_bay left] %>
  </td>
  <td valign=top>


<if 0 ne @budget_ctr@>
    <%= [im_box_header [_ intranet-budget.New_Budget_Docs]] %>
    @budget_menu;noquote@
    <%= [im_box_footer] %>
</if>


    <%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>
</div>



