<master>
  <property name="title">@title;noquote@</property>
  <property name="header_stuff">
    <link rel="stylesheet" type="text/css" href="/resources/bug-tracker/bug-tracker.css" media="all">
  </property>
  <property name="main_navbar_label">bug_tracker</property>
  <if @signatory@ not nil><property name="signatory">@signatory;noquote@</property></if>
  <if @focus@ not nil><property name="focus">@focus;noquote@</property></if>
  <property name="body_start_include">/packages/bug-tracker/lib/version-bar</property>
  <if @context_bar@ not nil>
    <property name="context_bar">@context_bar;noquote@</property>
  </if>
  <if @context@ not nil>
    <property name="context">@context;noquote@</property>
  </if>

<include src="nav-bar" notification_link="@notification_link;noquote@">

<slave>

<!-- include src="nav-bar" notification_link="@notification_link;noquote@" -->

