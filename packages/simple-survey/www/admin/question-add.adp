<master>
<property name=title>@name;noquote@: New Question</property>
<property name="context">@context;noquote@</property>

<form action="question-add-2" method=post>
<%= [export_form_vars survey_id after] %>

Question:
<blockquote>
<textarea name=question_text rows=5 cols=70></textarea>
</blockquote>
<%= [survey_specific_html $type] %>
<p>

Active? 
<input type=radio value=t name=active_p checked>Yes
<input type=radio value=f name=active_p>No
<br>
Required?
<input type=radio value=t name=required_p checked>Yes
<input type=radio value=f name=required_p>No

<center>
<input type=submit value="Continue">
</center>

</form>
