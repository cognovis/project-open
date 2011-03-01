<master>
<property name=title>Survey Administration: Add a Question (cont.)</property>
<property name="context">@context;noquote@</property>

<form action="question-add-3" method=post>
@form_var_list;noquote@

Question:
<blockquote>
@question_text@
</blockquote>

@presentation_options_html;noquote@

@response_type_html;noquote@

@response_fields;noquote@

<p>

Response Location: <input type=radio name=presentation_alignment value="beside"> Beside the question <input type=radio name=presentation_alignment value="below" checked> Below the question

<p>

<center>
<input type=submit value="Submit">
</center>

</form>
