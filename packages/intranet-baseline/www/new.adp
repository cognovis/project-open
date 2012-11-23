<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<if @show_components_p@>

    <%= [im_component_bay top] %>
    <table width="100%">
	<tr valign="top">
	<td width="50%">
		<%= [im_box_header [lang::message::lookup "" intranet-baseline.Baseline_Details "Baseline Details"]] %>
		<formtemplate id=form></formtemplate>
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
		    <formtemplate id=form></formtemplate>
		    <%= [im_box_footer] %>
                </td>
                <td>
			<%= [im_component_bay new_right] %> <!-- ToDo: validate -->
                </td>
                </tr>
            </table>

</else>

