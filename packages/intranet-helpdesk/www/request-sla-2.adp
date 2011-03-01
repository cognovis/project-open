<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>
<property name="sub_navbar">@ticket_navbar_html;noquote@</property>

<h1>@page_title@</h1>

<p>
<%= [lang::message::lookup "" intranet-helpdesk.Successfully_requested "You have successfully requested a new Service Level Agreement (SLA)."] %>
</p>
<p>&nbsp;</p>
<p>
<%= [lang::message::lookup "" intranet-helpdesk.Check_Inbox_for_email "Please check your Inbox for a confirmation email."] %>
</p>
<p>
<%= [lang::message::lookup "" intranet-helpdesk.Confirm_mail "You will receive another email once the support team has processed your request."] %>
</p>


