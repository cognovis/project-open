<master>
<property name="title">@page_title@</property>
<property name="context">context</property>
<property name="main_navbar_label">user</property>
<property name="sub_navbar">@sub_navbar_html;noquote@</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<table class="table_list_page">
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
</table>
