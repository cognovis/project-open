<master src=../../intranet-core/www/master>
<property name="context">@context;noquote@</property>
<property name="title">#intranet-spam.Spam#</property>
<property name="main_navbar_label">admin</property>

<h1>Sending Spam to Users</h1>

<p>
#intranet-spam.Send_Email_To#
<a href="@spam_show_users_url;noquote@">@num_recipients@ #intranet-spam.Member_s#</a> 
#intranet-spam.Of# <A href="@object_rel_url@">@object_name@</a>.
</p>
The following variables are available withing you message:<br>
<tt>@query_field_html@</tt>.


<form action="spam-confirm" method="post">
<%= [export_form_vars object_id sql_query num_recipients] %>
@export_vars;noquote@

<table>
 <tr>
  <td>List of Users</td>
  <td>
    <%= [im_selector_select selector_id $selector_id] %>
  </td>
 </tr>
 <tr>
  <td valign="top" align="left">#intranet-core.Subject#</td>
  <td><input type="text" name="subject" size="50" value="<if @title@ defined>@title@</if>">
 </tr>
 <tr>
  <td valign="top" align="left">#intranet-core.Date_Time_For_Message#</td>
  <td>@date_widget;noquote@ &nbsp; @time_widget;noquote@</td>
 </tr>
 <tr>
  <td valign="top" align="left">#intranet-core.Plain_Text_Message_Body#</td>
  <td>
    <textarea name="body_plain" rows="10" cols="70"
    ><if @plain_text@ defined>@plain_text@</if></textarea>
  </td>
 </tr>
 <tr>
  <td valign="top" align="left">#intranet-core.Html_Message_Body#</td>
  <td>
    <textarea name="body_html" rows="10" cols="70"
    ><if @html_text@ defined>@html_text@</if></textarea>
  </td>
 </tr>
 <tr>
   <td colspan=2>

<p>
The message will be sent out with MIME type <code>multipart/alternative</code>,<br>
with both plaintext and HTML parts, and the recipient's mail client should<br>
display the appropriate body.
</p>

<ul>
 <li>If the text body is filled in and the HTML body is left blank, <br>
  it will be sent as <code>text/plain</code>
 <li>If the HTML body is filled in and the text body is left blank, <br>
 it will be sent as <code>text/html</code>
</ul>

    </td>
  </tr>
</table>


<center><input type="submit" value="Go To Validate"></center>



</form>



