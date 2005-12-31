<master>
<property name=title>@survey_name;noquote@: Edit Name</property>
<property name="context">@context;noquote@</property>

<blockquote>
Edit and submit to change the name for this survey:
<form method=post action="name-edit-2">
<%= [export_form_vars survey_id] %>
<INPUT TYPE=text name=name value="@survey_name@" size=80>
<br>

<center>
<input type=submit value=Update>
</center>

</blockquote>
