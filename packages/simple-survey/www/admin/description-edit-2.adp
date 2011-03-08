<master>
<property name=title>Edit Description Confirmation</property>
<property name="context">@context;noquote@</property>

Here is how your survey description will appear:
<blockquote><p>
@description@
<form method=post action="<%= [ns_conn url] %>">
<%= [export_form_vars description desc_html survey_id] %>
<input type=hidden name=checked_p value="t">
<br><center><input type=submit value="Confirm"></center>
</form>
</blockquote>

<font size=-1 face="verdana, arial, helvetica">
Note: if the text above has a bunch of visible HTML tags then you probably
should have selected "HTML" rather than "Plain Text". If it is all smashed together
and you want the original line breaks saved then choose "Preformatted Text".
Use your browser's Back button to return to the submission form.
</font>
    
