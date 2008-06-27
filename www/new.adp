<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">helpdesk</property>
<property name="focus">@focus;noquote@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<if @show_components_p@>
      <%= [im_component_bay top] %>
</if>
<table width="100%">
  <tr valign="top">
    <td width="50%">
      <%= [im_box_header $page_title] %>
      <formtemplate id="ticket"></formtemplate>
      <%= [im_box_footer] %>
	<if @show_components_p@>
	      <%= [im_component_bay left] %>
	</if>
    </td>
    <td width="50%">
	<if @show_components_p@>
		<%= [im_component_bay right] %>
	</if>
	<else>
	      <%= [im_box_header "Basic Information About You"] %>
	      <formtemplate id="userinfo"></formtemplate>
	      <%= [im_box_footer] %>

	      <%= [im_box_header "Your Complete Contact Information"] %>
	      <%= $contact_html %>
	      <%= [im_box_footer] %>
	</else>
    </td>
  </tr>
</table>

<if @show_components_p@>
      <%= [im_component_bay bottom] %>
</if>
