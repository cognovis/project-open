<master>
<property name="title">@page_title@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="main_navbar_label">expenses</property>
<!-- <property name="focus">@focus;noquote@</property> -->

<h2>@page_title@</h2>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<formtemplate id="@form_id@"></formtemplate>


