<!-- packages/intranet-forum/www/index.adp -->
<!-- @author Juanjo Ruiz (juanjoruizx@yahoo.es) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">forum</property>


<ul>
<li><a href="">Download GanttProject</a>
<li><a href="house_test.gan">House Test Gantt</a>
<li><a href="ganttproject.jnlp">WebStart</a>
<li><a href="ganttproject.gan">ganttproject.gan</a>
</ul>


<form enctype=multipart/form-data method=POST action=gantt-upload-2.tcl>
<%= [export_form_vars return_url] %>
<table border=0>
  <tr>
    <td class=rowtitle align=center colspan=2>Upload a GanttProject file</td>
  </tr>
  <tr $bgcolor(1)>
    <td align=right>File</td>
    <td>
      <input type=file name=upload_file size=30>
    </td>
  </tr>
  <tr $bgcolor(0)>
    <td></td>
    <td>
      <input type=submit value='Submit'><br>
    </td>
  </tr>
</table>
</form>
