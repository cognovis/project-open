<if @enable_master_p@>
	<master>
	<property name=title>One Survey: @name;noquote@</property>
	<property name="context">@context;noquote@</property>
	<br>
	@project_menu;noquote@
	
	<if "" ne @message@>
	@message;noquote@
	</if>
	
	<h1><%= [lang::message::lookup "" simple-survey.Fill_out_survey "Please fill out the survey below. Thank you for your cooperation."] %><h1>
	<br>
	<p>
	@description;noquote@
	</p>
</if>

<form enctype=multipart/form-data method="post" action="@package_url;noquote@/process-response">
<%= [export_form_vars survey_id related_object_id related_context_id task_id return_url] %>
<table border="0" cellpadding="0" cellspacing="0" width="100%">
    <tr>
      <td class="tabledata">
        <include src=one_@display_type;noquote@ questions=@questions;noquote@>
        <hr noshapde size="1" color="#dddddd">
          <input type=submit value="Continue">
      </td>
    </tr>
</table>
</form>
