<!-- packages/intranet-forum/www/index.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">projects</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>


<!-- ------------------------------------------------------------------------------ -->
<%= [im_box_header [lang::message::lookup "" intranet-ganttproject.Upload "Upload"]] %>
<p>
  <br/>
  <%= [lang::message::lookup "" intranet-ganttproject.Upload_Project_File \
      "Upload @program_name@ '.xml' File"] %>:
  <br/>
</p>
<form enctype="multipart/form-data" method="POST" action="gantt-upload-2">
<%= [export_form_vars project_id return_url] %>
<table border=0>
  <tr>
    <td><%= [lang::message::lookup "" intranet-core.File "File"] %></td>
    <td>
      <input type="file" name="upload_gan" size="30">
    </td>
  </tr>
  <tr>
    <td></td>
    <td>
      <input type="submit" name="button_gan" value="Submit">
    </td>
  </tr>
</table>
</form>
<br>

<!-- --------------------------------------------------------------------------------- -->
<h3><%= [lang::message::lookup "" intranet-ganttproject.Please_Note "Please note"] %></h3>
<ul>

<if @import_type@ eq openproj>
<li><%= [lang::message::lookup "" intranet-ganttproject.With_OpenProj_save_as_XML "
	With OpenProj, please save your file in format 'MS Project 2003 XML (*.xml)'
	and upload this XML file here.
"] %>
</if>

<if @import_type@ eq microsoft_project>
<li><%= [lang::message::lookup "" intranet-ganttproject.With_MS_Project_save_as_XML "
	With Microsoft Office Project, please save your file in format 'Format XML (*.xml)'
	and upload this XML file here.
"] %>
</if>

<if @import_type@ eq gantt_project>
<li><%= [lang::message::lookup "" intranet-ganttproject.Gantt_Project_Note "
	With GanttProject, it is OK to upload the normal '.gan' file here.
"] %>
</if>

</ul>

<%= [im_box_footer] %>


<!-- ---------------------------------------------------------------------------------- -->
<%= [im_box_header [lang::message::lookup "" intranet-ganttproject.Software "Software"]] %>
<ul>
        <li><a href="http://ganttproject.biz/">Download GanttProject Software</a></li>
	<li><a href="http://openproj.org/openproj">Download OpenProj Software</a></li>
	<li><a href="http://www.microsoft.com/project/">Info about Microsoft Office Project</a></li>

</ul>
<%= [im_box_footer] %>

