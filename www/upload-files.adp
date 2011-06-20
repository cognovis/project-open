<master src="@master_file;noquote@">
<property name="title">@page_title;noquote@</property>
<property name="show_left_navbar_p">@show_left_navbar_p;noquote@</property>
<br>

<!--@company_placeholder;noquote@-->
<h1>Request for Quote</h1>
<p>Please upload the files and provide the relevant information. Once you have uploaded all files, please use "Continue" to send your inquiry.</p>    

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

<br><br>
    <div id="upload_file_placeholder"></div>
    <form id="form_source_language">@source_language_combo;noquote@<div id="source_language_placeholder"></div></form>
    <div id="form_target_languages"></div>    
    <div id='delivery_date_placeholder'></div>
<br>
    <div><button id="btnSendFileandMetaData">Upload file and store attributes</button></div>
<br><br>

<b> Files already uploaded for this "Request for Quote":
<br><br>
<table cellpadding="0" cellspacing="0" border="0">
<tr>
	<!--<td><div id="panel_files_uploaded_placeholder"></div></td>
	<td><div id="panel_uploaded_files"></div></td>-->
	<td><div id="grid_uploaded_files"></div></td>
</tr>
<tr>
	<td colspan="2" align="right"><button id="continue">Request Quote >></button></td>
</tr>

</table>


<div id="sidebar"></div>
