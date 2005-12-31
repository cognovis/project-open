<master>
<property name=title>Survey Administration: Create New Survey</property>
<property name="context">@context;noquote@</property>

<blockquote>

<form method=post action="survey-create-2">
<%= [ad_export_vars -form type] %>
<p>

Survey Name:  <input type=text name=name value="@name@" size=21 maxlength=20>
<p>
Survey Description: 
<br>
<textarea name=description rows=10 cols=65>@description@</textarea>
<br>
The description above is: 
<input type=radio name=desc_html value="pre">Preformatted text
<input type=radio name=desc_html value="plain" checked>Plain text
<input type=radio name=desc_html value="html">HTML
<p>
<%= [survey_specific_html $type] %>
<p>
Display Type: <%= [survsimp_display_type_select -name display_type -value list] %>
<center>
<input type=submit value="Create">
</center>
</form>

</blockquote>
