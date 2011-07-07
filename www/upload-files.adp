<master src="@master_file;noquote@">
<property name="title">@page_title;noquote@</property>
<property name="show_left_navbar_p">@show_left_navbar_p;noquote@</property>
<!--@company_placeholder;noquote@-->
<h1>Request for Quote:</h1>

<!--<p>Please upload the files and provide the relevant information. Once you have uploaded all files, please click "Request Quote" to send your inquiry.</p>-->    

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

<table>
<tr>
	<td><b><!--Upload Files:--></b></td>	
	<td></td>
	<td><b><span id='titleUploadedFiles'>Files already uploaded for this RFQ:</b></span></td>
</tr>
<tr><td colspan="3">&nbsp;</td></tr><tr>
<td align='top'>
	<div id="upload-form">
	<table>
	<tr>
		<td>
		    <div id='delivery_date_placeholder'></div>
		</td>
		<td>
		    <div id="upload_file_placeholder"></div>

		</td>
	</tr>
	<tr>
		<td colspan="2">
		    <form id="form_source_language">@source_language_combo;noquote@<div id="source_language_placeholder"></div></form>
		</td>
	</tr>
	<tr>
	<td colspan='2'>
		    <div id="form_target_languages"></div>    
	</td>
	</tr>
	<tr><td>&nbsp;</td></tr>

	<tr>
		<td colspan="2" align="center">
	
	<div class="buttons"><button id="btnSendFileandMetaData">Upload file</button></div>
		</td>
	</tr>
	</table>
	</div>
</td>
	<td>&nbsp;&nbsp;</td>
<td align='top'>
	<span id='tableUploadedFiles'>
	<table cellpadding="0" cellspacing="0" border="0">
		<tr>
		<td><div id="grid_uploaded_files"></div></td>
		</tr>
	</table>
	</span>

</td>
</tr>

<tr><td><br><br></td></tr>

<tr>
<td colspan="3" align="center">
<span id='sendButtons' class="buttons">
<form id="form_request_quote" name="form_request_quote" action="/intranet-customer-portal/upload-files-action" method="post">
	
<table>
<tr>
	<td>
		<b>Comments:</b><br><br><textarea name="comment" cols="40" rows="10"></textarea><br><br>
	</td>
</tr>
<tr>
	<td>
	<input type="hidden" name="security_token" value="@security_token;noquote@"> 
	<input type="hidden" name="inquiry_id" value="@inquiry_id;noquote@"> 
	<input type="hidden" name="btn_value" value=""> 
	<input name="btnSubmit" type="button" id="btnSubmit" value="Done, Request Quote" onclick="document.forms['form_request_quote'].btn_value.value='submit'; document.forms['form_request_quote'].submit();">&nbsp;
	<input name="btnCancel" type="button" id="btnCancel" value="Cancel and remove all files" onclick="document.forms['form_request_quote'].btn_value.value='cancel'; document.forms['form_request_quote'].submit();"
	</td>
</tr>
</table>

</form>
</span>

</td>
</tr>
</table>

<div id="sidebar"></div>
