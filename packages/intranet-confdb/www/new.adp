<!-- packages/intranet-confdb/www/new.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->
<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">

<if @enable_master_p@>
<master src="../../intranet-core/www/master">
</if>

<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">conf_items</property>
<property name="focus">@focus;noquote@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>


<if @view_name@ eq "component">

   <%= [im_component_page -plugin_id $plugin_id -return_url "/intranet-helpdesk/new?ticket_id=$ticket_id"] %>

</if>
<else>

	
	<if @show_components_p@>
	
		<%= [im_component_bay top] %>
		<table width="100%">
		  <tr valign="top">
		    <td width="50%">
			<%= [im_box_header [lang::message::lookup "" intranet-confdb.Conf_Item "Configuration Item"]] %>
			<formtemplate id="conf_item"></formtemplate>
			<%= [im_box_footer] %>
			<%= [im_component_bay left] %>
		    </td>
		    <td width="50%">

			<if @sub_item_count@>
			<%= [im_box_header [lang::message::lookup "" intranet-confdb.Sub_Items "Sub-Items"]] %>
			<listtemplate name="sub_conf_items"></listtemplate>
			<%= [im_box_footer] %>
			</if>

			<%= [im_component_bay right] %>

		    </td>
		  </tr>
		</table>
		<%= [im_component_bay bottom] %>

	</if>
	<else>
	
		<%= [im_box_header $page_title] %>
		<formtemplate id="conf_item"></formtemplate>
		<%= [im_box_footer] %>
	
	</else>

</else>


<table width="100%">
  <tr valign="top">
  <td>
	@result;noquote@
  </td>
  </tr>
</table>
