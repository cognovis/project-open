<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>

<if @show_filter_p@ eq t>
    <listfilters name="messages" style="select-menu"></listfilters>
</if>
<listtemplate name="messages"></listtemplate>
