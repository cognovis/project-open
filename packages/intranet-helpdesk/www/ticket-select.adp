<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>
<property name="sub_navbar">@ticket_navbar_html;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT>

<table cellspacing=0 cellpadding=0 border=0 width="100%">
<form action="@return_url;noquote@" method=GET>

   <%= [export_form_vars action_id return_url] %>
   <tr valign=top>
   <td>
	<%= [im_box_header $page_title] %>
            <table class=\"list\">
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
            <%= $table_submit_html %>
	    </table>
	<%= [im_box_footer] %>
   </td>
   </tr>
   <tr>
   <td>
	<%= [im_box_header [lang::message::lookup "" intranet-helpdesk.Tickets_for_duplicate "Tickets to be marked as duplicate"]] %>
	<listtemplate name="duplicated_tickets"></listtemplate>
	<%= [im_box_footer] %>
   </td>
   </tr>

</form>
</table>
