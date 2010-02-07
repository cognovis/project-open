<!-- packages/intranet-forum/www/index.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">projects</property>


<%= [im_box_header [lang::message::lookup "" intranet-ganttproject.Upload "Upload"]] %>
<p>
  <br/>
  <%= [lang::message::lookup "" intranet-ganttproject.Upload_GanttProject_or_OpenProj_File \
      "Upload a GanttProject .gan or OpenProj XML File"] %>:
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
<h3><%= [lang::message::lookup "" intranet-ganttproject.Please_Note "Please note"] %></h3>
<ul>
<li><%= [lang::message::lookup "" intranet-ganttproject.With_OpenProj_save_as_XML "
	With OpenProj, please save your file in format 'MS Project 2003 XML (*.xml)'
	and upload this XML file.
"] %>
</ul>
<%= [im_box_footer] %>


<%= [im_box_header [lang::message::lookup "" intranet-ganttproject.Software "Software"]] %>
<ul>
        <li><a href="http://ganttproject.biz/">Download GanttProject Software</a></li>
	<li><a href="http://openproj.org/openproj">Download OpenProj Software</a></li>
</ul>
<%= [im_box_footer] %>

