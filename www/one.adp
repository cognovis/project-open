<master>
<property name=title>One Survey: @name;noquote@</property>
<property name="context">@context;noquote@</property>
<br>
@project_menu;noquote@

<if "" ne @message@>
@message;noquote@
</if>

<h1><%= [lang::message::lookup "" simple-survey.Fill_out_survey "Fill out Survey"] %><h1>

<p>
@description;noquote@
</p>

<table border="0" cellpadding="0" cellspacing="0" width="100%">
  <form enctype=multipart/form-data method="post" action="process-response">
	<%= [export_form_vars return_url ] %>
    <tr>
      <td class="tabledata"><hr noshade size="1" color="#dddddd"></td>
    </tr>
    
    <tr>
      <td class="tabledata">
        <%= [export_form_vars survey_id related_object_id related_context_id] %>
        <include src=one_@display_type;noquote@ questions=@questions;noquote@>
        <hr noshapde size="1" color="#dddddd">
          <input type=submit value="Continue">
      </td>
    </tr>
    
  </form>
</table>
