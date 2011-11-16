<!-- packages/intranet-forum/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->
<!-- @author Klaus Hofeditz (klaus.hofeditz@project-open.com) -->

<!DOCTYPE HTML PUBLIC "-//W3C//DTD HTML 4.01//EN">
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="main_navbar_label">reporting</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>
<br>
<h1><%=[lang::message::lookup "" intranet-reporting.ListOfCurrentProjectTasks "List of Current Project Tasks"]%></h1> 
<p>
<%=[lang::message::lookup "" intranet-reporting.ListOfCurrentProjectTasksIntro "This report lists time sheet tasks for projects of type \"Consulting\" (including sub-types)."]%>
</p>
<br><br><br>
@component_html;noquote@
