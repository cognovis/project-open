<!-- common form components to spam add/edit pages -->

<table>
 <tr>
  <td valign="top" align="left">#intranet-spam.Subject#</th>
  <td><input type="text" name="subject" size="50" 
	value="<if @title@ defined>@title@</if>">
 </tr>
 <tr>
  <td valign="top" align="left">#intranet-spam.Date_Time_For_Message#</th>
  <td>@date_widget;noquote@ &nbsp; @time_widget;noquote@</td>
 </tr>
 <tr>
  <td valign="top" align="left">#intranet-spam.Plain_Text_Message_Body#</th>
  <td><textarea name="body_plain" rows="10" cols="40"><if @plain_text@ defined>@plain_text@</if></textarea>
  </td>
 </tr>
 <tr>
  <td valign="top" align="left">#intranet-spam.Html_Message_Body#</th>
  <td><textarea name="body_html" rows="10" cols="40"><if @html_text@ defined>@html_text@</if></textarea>
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
 



  

