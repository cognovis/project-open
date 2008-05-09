<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context;noquote@</property>
<property name="main_navbar_label">bug_tracker</property>


<div class="filter-list">

   <include src="../lib/nav-bar" notification_link="">

   <div class="filter">
      <div class="filter-block">
         <listfilters name="bugs"></listfilters>
      </div>
   </div>

   <div class="fullwidth-list" style="min-height: 800px;">
      <%= [im_box_header $page_title] %>
      <listtemplate name="bugs"></listtemplate>
      <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>


