<master src=../../intranet-core/www/master>
<property name="context">@context;noquote@</property>
<property name="title">#intranet-core.Spam#</property>
<property name="main_navbar_label">admin</property>

<h1>Sending Spam to Users</h1>

<p>
#intranet-core.Send_Email_To#
<a href="@spam_show_users_url;noquote@">@num_recipients@ #intranet-core.Member_s#</a> 
#intranet-core.Of# <A href="@object_rel_url@">@object_name@</a>.
</p>
The following variables are available withing you message:<br>
<tt>@query_field_html@</tt>.


<form action="spam-confirm" method="post">
<%= [export_form_vars object_id sql_query num_recipients] %>
@export_vars;noquote@

<include src="spam-form-body" 
	time_widget=@time_widget;noquote@ 
	date_widget=@date_widget;noquote@
>



<center><input type="submit" value="Go To Validate"></center>



</form>



