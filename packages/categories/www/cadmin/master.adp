<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context_bar;noquote@</property>
<if @focus@ not nil><property name="focus">@focus;noquote@</property></if>

<if @change_locale@ eq t and @languages@ not nil>
  <div style="float: right;">
    <formtemplate id="locale_form"></formtemplate>
  </div>
</if>

<slave>
