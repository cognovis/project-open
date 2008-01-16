<if @enable_master_p@>
<master>
<property name="title">@page_title@</property>
<property name="main_navbar_label">timesheet</property>
</if>

<h2>@page_title@</h2>
<formtemplate id=form></formtemplate>

<br>

<h2>@included_hours_msg@</h2>
@modify_hours_link;noquote@
<listtemplate name=@list_id@></listtemplate>
