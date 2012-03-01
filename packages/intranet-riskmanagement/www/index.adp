<master>
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">@main_navbar_label@</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>
<property name="show_context_help">@show_context_help_p;noquote@</property>


<if @master_p@>
</if>

<%= [im_box_header $page_title] %>
@risk_html;noquote@
<%= [im_box_footer] %>

