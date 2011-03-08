<if @is_wizard@ eq f>
  <master src="../../master">
  <property name="title">@page_title;noquote@</property>
</if>
<h2>@page_title@</h2>

<if @is_wizard@ eq t>
  <formtemplate id="create_item" style="wizard"></formtemplate>
</if>
<else>
  <formtemplate id="create_item"></formtemplate>
</else>
