<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="admin_navbar_label">admin_material</property>
<property name="focus">@focus;noquote@</property>

<h2>@page_title@</h2>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<formtemplate id="material"></formtemplate>

