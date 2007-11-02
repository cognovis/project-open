<master src="../../intranet-core/www/master">
<property name="context">@context;noquote@</property>
<property name="title">@page_title@</property>
<property name="main_navbar_label">reporting</property>

<%= [im_box_header $page_title] %>
<listtemplate name="report_list"></listtemplate>
<%= [im_box_footer] %>


