<master>
<property name="title">Edit an outgoing spam</property>
<property name="context">@context;noquote@</property>

<form action="spam-confirm" method="post">
@export_vars;noquote@
 <include src="spam-form-body" 
	plain_text=@plain_text;noquote@
	html_text=@html_text;noquote@
	title=@title;noquote@
	date_widget=@date_widget;noquote@
	time_widget=@time_widget;noquote@>

<center><input type="submit" value="Edit Spam"></center>
</form>