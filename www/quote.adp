<if @enable_master_p@>
<master src="../../intranet-core/www/master">
</if>

<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">helpdesk</property>
<property name="focus">@focus;noquote@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<if @message@ not nil>
  <div class="general-message">@message@</div>
</if>

<%= [im_box_header $page_title] %>
<formtemplate id="ticket"></formtemplate>
<%= [im_box_footer] %>
