<if @show_master_p@>
<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">projects</property>
</if>

<style>
.fullwidth-list .component table.taskboard td {
     vertical-align:top;
}
</style> 

<table class="taskboard">
<tr>
@top_html;noquote@
</tr>
<tr>
@body_html;noquote@
</tr>
</table>

