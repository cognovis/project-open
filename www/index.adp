<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">@main_navbar_label@</property>

<form enctype="multipart/form-data" method=POST action="import-2.tcl">
<%= [export_form_vars return_url main_navbar_label] %>

     <table border=0>
     <tr> 
	<td>#intranet-csv-import.Object_Type#</td>
	<td> 
<%= [im_select object_type [list \
	      im_project "Project" \
	      im_risk "Risk" \
	      im_timesheet_task "Timesheet Task" \
	      person "User" \
] $object_type] %>

<!--	      im_company "Company" \ -->

	</td>
     </tr>

     <tr> 
	<td>Filename</td>
	<td> 
	  <input type=file name=upload_file size=30>
	<%= [im_gif help "Use the &quot;Browse...&quot; button to locate your file, then click &quot;Open&quot;."] %>
	</td>
     </tr>

     <tr> 
	<td></td>
	<td> 
	  <input type=submit>
	</td>
    </tr>

    </table>
</form>



<table>
<tr>
<td>
We espect that the import file contains the column names in the first row.
</td>
</tr>
</table>

