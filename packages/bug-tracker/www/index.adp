<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">bug_tracker</property>
<property name="show_left_navbar_p">1</property>
<property name="left_navbar">@left_navbar_html;noquote@</property>

<include src="../lib/nav-bar" notification_link="">
<listtemplate name="bugs"></listtemplate>
<div class="filter-list-footer"></div>
