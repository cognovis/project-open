<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">timesheet</property>

<h2>@page_title@</h2>

<p>
Creating workflows for all hours logged between @start_date@ - @end_date@.
</p>
<br>

<ul>
@li_html;noquote@
</ul>


<br>&nbsp;<br>

<p>
<a href="@return_url;noquote@"
><%= [lang::message::lookup "" intranet-timesheet2-workflow.Return_to_previous_page "Return to previous page"] %></a>
</p>
<br>
