<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">tinytm</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<!-- Filter & Admin Section -->
<table border=0 cellpadding=0 cellspacing=1>
<tr>
  <td>

	<formtemplate id=@form_id@></formtemplate>

  </td>
  <td>&nbsp;</td>
  <td valign=top width='30%'>

    <table border=0 cellpadding=0 cellspacing=0>
    <tr>
      <td class=rowtitle align=center>
        #intranet-core.Admin_Projects#
      </td>
    </tr>
    <tr>
      <td>

        @admin_html;noquote@

      </td>
    </tr>
    </table>

  </td>
</tr>
</table>


<!-- content section -->
<table cellpadding=0 cellspacing=0 border=0 width=100%>
<tr>
  <td valign=top width="50%">
	<%= [im_component_bay left] %>
  </td>
  <td valign=top with="50%">
	<%= [im_component_bay right] %>
  </td>
</tr>
</table><br>

<table cellpadding=0 cellspacing=0 border=0>
<tr><td>
  <%= [im_component_bay bottom] %>
</td></tr>
</table>

<%= $project_navbar_html %>
<table width=100% cellpadding=2 cellspacing=2 border=0>
  <%= $table_header_html %>
  <%= $table_body_html %>
  <%= $table_continuation_html %>
</table>






