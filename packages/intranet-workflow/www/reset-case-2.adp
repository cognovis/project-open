<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">rfc</property>

<if @button_cancel@ ne "">
<h1><%= [lang::message::lookup "" intranet-workflow.Action_Canceled "Action Canceled"] %></h1>
<%= [lang::message::lookup "" intranet-workflow.Action_Canceled_message "No action has been performed."] %>
</if>

<if @button_confirm@ ne "">
<h1><%= [lang::message::lookup "" intranet-workflow.Action_Performed "Action Performed"] %></h1>
<%= [lang::message::lookup "" intranet-workflow.Action_Canceled_message "Action '%action_pretty%' has been executed successfully."] %>
</if>

<p>&nbsp;</p>

<ul>
<li><a href="@return_url;noquote@"><%= [lang::message::lookup "" intranet-workflow.Back_to_last_page "Back to last page"] %></a>.
</ul>
