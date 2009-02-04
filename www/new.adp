<if @enable_master_p@>
<master src="../../intranet-core/www/master">
</if>

<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">helpdesk</property>
<property name="focus">@focus;noquote@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT>


<div class="filter-list">

    <a id="sideBarTab" href="#"><img id="sideBarTabImage" border="0" title="sideBar" alt="sideBar" src="/intranet/images/navbar_saltnpepper/slide-button-active.gif"/></a>
    <div class="filter" id="sidebar">
	<div id="sideBarContentsInner"> 
	    <div class="filter-block">
		<div class="filter-title">
		    <%= [lang::message::lookup "" intranet-core.Filter_Tickets "Filter Tickets"] %>
		</div>
		<formtemplate id="ticket_filter"></formtemplate>
	    </div>
	    <hr/>

<if @sla_exists_p@>
	    <div class="filter-block">
		<div class="filter-title">
		    <%= [lang::message::lookup "" intranet-core.Admin_Tickets "Admin Tickets"] %>
		</div>
		@admin_html;noquote@
	    </div>
	    <hr/>
</if>

	    <%= [im_navbar_tree -label "main"] %>

	</div> <!-- id="sideBarContentsInner" -->
    </div> <!-- class="filter" -->


    <div id="fullwidth-list" class="fullwidth-list">
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
			<%= [im_box_header [lang::message::lookup "" intranet-helpdesk.Ticket_Details "Ticket Details"]] %>
			<formtemplate id="ticket"></formtemplate>
			@ticket_action_html;noquote@
			@notification_html;noquote@
			<%= [im_box_footer] %>
			<%= [im_component_bay left] %>
		</td>
		<td width="50%">
			<%= [im_component_bay right] %>
		</td>
		</tr>
	    </table>
	    <%= [im_component_bay bottom] %>
	    </if>
	    <else>
	    <%= [im_box_header $page_title] %>
	    <formtemplate id="ticket"></formtemplate>
	    <%= [im_box_footer] %>
	    </else>
	</else>
    </div> <!-- class="fullwidth-list" id="fullwidth-list" -->

</div> <!-- class="filter-list" -->

