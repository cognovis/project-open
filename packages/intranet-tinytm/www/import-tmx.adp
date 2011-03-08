<!-- packages/intranet-tinytm/www/import-tmx.adp -->
<!-- @author frank.bergmann@project-open.com -->
<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">tinytm</property>

<h1>@page_title;noquote@</h1>

<form enctype="multipart/form-data" method=POST action="import-tmx-2">
<%= [export_form_vars return_url] %>
    <table border=0>
     <tr> 
	<td>#intranet-tinytm.Filename#</td>
	<td> 
	  <input type=file name=upload_file size=30>
	</td>
     </tr>
      <tr> 
	<td>Company Type</td>
	<td> 
	  <%= [im_select -translate_p 1 encoding $encoding_options "utf-8"] %>
	</td>
      </tr>
      <tr valign=middle> 
	<td>Action</td>
	<td>
	<input type=radio name=action value=test checked>&nbsp; Test if encoding is OK
	<input type=radio name=action value=sdfg>&nbsp; Import the data
	</td>
      </tr>
      <tr> 
	<td></td>
	<td> 
	  <input type=submit value="#intranet-tinytm.Submit#">
	</td>
      </tr>
    </table>
</form>
<p>&nbsp;</p>

<table border=0 cellspacing=0 cellpadding=1 width="70%">
<tr><td>
<h1>Import TMX Files</h1>

<p>
This function will import a TMX file into TinyTM.<p>
All of the included segments will be added to TinyTM under the name
of the current user.<p>

</td></tr>
</table>
