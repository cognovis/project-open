<if @enable_master_p@><master></if>
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">event</property>
<property name="focus">@focus;noquote@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT>
@message_html;noquote@

<if @message@ not nil>
    <div class="general-message">@message@</div>
</if>
<if @view_name@ eq "component">
    <%= [im_component_page -plugin_id $plugin_id -return_url "/intranet-events/new?event_id=$event_id"] %>
</if>
<else>
    <if @show_components_p@>
    <%= [im_component_bay top] %>
    <table width="100%">
	<tr valign="top">
	<td width="50%">
		<%= [im_box_header "[lang::message::lookup "" intranet-events.Event_Details "Event Details"]"] %>
		<formtemplate id="event"></formtemplate>
		@event_action_html;noquote@
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

            <table width="100%">
                <tr valign="top">
                <td>
		    <%= [im_box_header $page_title] %>
		    <formtemplate id="event"></formtemplate>
		    <%= [im_box_footer] %>
                </td>
                <td>
			<%= [im_component_bay new_right] %> <!-- ToDo: validate -->
                </td>
                </tr>
            </table>

    </else>
</else>

