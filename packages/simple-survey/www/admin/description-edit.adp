<master>
<property name=title>@survey_name;noquote@: Edit Description</property>
<property name="context">@context;noquote@</property>

<blockquote>
Edit and submit to change the description for this survey:
<form method=post action="description-edit-2">
<%= [export_form_vars survey_id] %>
<textarea name=description rows=10 cols=65>@description@</textarea>  
<br>
The description above is:
<input type=radio name=desc_html value="pre">Preformatted text
<%= [survsimp_bt_mergepiece  "<input type=radio name=desc_html value=\"f\">Plain text
<input type=radio name=desc_html value=\"t\">" $html_p_set] %> HTML
<P>

<center>
<input type=submit value=Update>
</center>

</blockquote>
