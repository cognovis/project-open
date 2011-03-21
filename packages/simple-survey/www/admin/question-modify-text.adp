<master>
<property name=title>@survey_name;noquote@: Modify Question Text</property>
<property name="context">@context;noquote@</property>

<form action="question-modify-text-2" method=GET>
<%= [export_form_vars question_id survey_id] %>
Question:
<blockquote>
<textarea name=question_text rows=5 cols=70><%= [ns_quotehtml $question_text] %></textarea>
</blockquote>

<p>

<center>
<input type=submit value="Continue">
</center>


</form>
