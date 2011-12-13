<master src="@master_file;noquote@">
<property name="title">@page_title;noquote@</property>
<property name="show_left_navbar_p">@show_left_navbar_p;noquote@</property>
<property name="main_navbar_label">intranet_customer_portal</property>

  <!--[if IE]>
	
	<style type="text/css">
	/* #source_language_placeholder { margin-top: -12px } */ 
    	</style>
  <![endif]-->

<!--@company_placeholder;noquote@-->
<!--<p>Please upload the files and provide the relevant information. Once you have uploaded all files, please click "Request Quote" to send your inquiry.</p>-->    
<br><br>
<if @anonymous_p@ false>
<!--
<td valign="top">
<b>Project</b>
</td>
-->
</if>

<if @anonymous_p@ false>
<!--<td valign="top">
	<%=[im_project_select -include_empty_p 1 -include_empty_name "New project" -project_status_id [im_project_status_open] -exclude_subprojects_p 0 project_id "" "open"]%>
</td>-->
</if>


<table cellpadding="0" cellspacing="0" border="0">
<tr>
	<td> 
		<!-- Upload Form -->
		<div id="upload-form">
			<table border="0">
			<tr>
				<td valign="top"><div id="upload_file_placeholder"></div> </td>
				<td valign="top"><div id='delivery_date_placeholder'></div> </td>
				<td valign="top"><form id="form_source_language">@source_language_combo;noquote@<div id="source_language_placeholder"></div></form> </td>
				<td valign="top"><div id="form_target_languages"</div> </td>
				<td valign="top"><div class="buttons" style="margin-top: 20px"><button id="btnSendFileandMetaData">Upload file</button></div></td>
			</tr>
			</table>
		</div>
	</td>
</tr>
</table>



<!-- File Viewer & Comments --> 
<br><br>

<span id='sendButtons' class="buttons">
<form id="form_request_quote" name="form_request_quote" action="/intranet-customer-portal/upload-files-action" method="post">

	<input type="hidden" name="security_token" value="@security_token;noquote@"> 
	<input type="hidden" name="inquiry_id" value="@inquiry_id;noquote@"> 
	<input type="hidden" name="btn_value" value=""> 

<table cellpadding="0" cellspacing="0" border="0">
<tr>
	<td valign="top"><span id='titleUploadedFiles'><b>Files already uploaded for this RFQ:</b></span></td>
        <td>&nbsp;&nbsp;&nbsp;</td>
	<td valign="top"><b>Comments:</b><td>
</tr>
<tr>
        <td colspan="3">&nbsp;&nbsp;&nbsp;</td>
</tr>

<tr>
        <td valign="top">
		<!-- File Viewer --> 
		<span id='tableUploadedFiles'><div id="grid_uploaded_files"></div></span>
	</td>
	<td></td>
        <td valign="top" align="center">
		<textarea name="comment" cols="50" rows="14"></textarea><br><br>	
		<input name="btnSubmit" type="button" id="btnSubmit" value="Send quote request" onclick="document.forms['form_request_quote'].btn_value.value='submit'; document.forms['form_request_quote'].submit();">&nbsp;
		<input name="btnCancel" type="button" id="btnCancel" value="Cancel" onclick="document.forms['form_request_quote'].btn_value.value='cancel'; document.forms['form_request_quote'].submit();"
        </td>
</tr>

</table>
</form>
</span>		

<div id="sidebar"></div>
<div id="slave_content"></div>


<script type="text/javascript">
	<%=$js_include%>
</script>
