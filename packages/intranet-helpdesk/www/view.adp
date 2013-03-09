<master src="../../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">helpdesk</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<% set return_url [im_url_with_query] %>

<table width="100%">
  <tr valign="top">
    <td width="50%">
      <%= [im_component_bay left] %>
    </td>

    <td width="50%">
      <%= [im_component_bay right] %>
    </td>

  </tr>
  <tr>
    <td colspan=2>
      <%= [im_component_bay bottom] %>
    </td>
  </tr>
</table>

