<master src="../../master">
<property name=title>#acs-subsite.Upload_Portrait#</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">user</property>

<h1>#acs-subsite.lt_How_would_you_like_the#</h1>

<p>

#acs-subsite.lt_Upload_your_favorite#

<blockquote>

<!--
<form enctype=multipart/form-data method=POST action="upload-2">
@export_vars;noquote@
<table>
  <tr>
    <td valign=top align=right>#acs-subsite.Filename#: </td>
    <td><input type=file name=upload_file size=20><br>
        <font size=-1>#acs-subsite.lt_Use_the_Browse_button#</font>
    </td>
  </tr>
  <tr>
    <td valign=top align=right>#acs-subsite.Story_Behind_Photo#<br>
       <font size=-1>#acs-subsite.optional#</font>
    </td>
    <td><textarea rows=6 cols=50 wrap="<%=[im_html_textarea_wrap]%>" name=portrait_comment></textarea></td>
  </tr>
</table>
<p>
<center>
<input type=submit value="Upload">
</center>
</blockquote>
</form>
-->

<form enctype=multipart/form-data method=POST action=upload-2.tcl>
<%= [export_form_vars user_id return_url] %>
<table cellspacing=0 cellpadding=0>
<tr>
<td><input type=file name=upload_file size=25></td>
<td><input type=submit name=button_gan></td>
</tr>
</table>
</form>


