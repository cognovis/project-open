<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>
<property name="sub_navbar">@ticket_navbar_html;noquote@</property>

<div class="filter-list">
<a id="sideBarTab" href="#"><img id="sideBarTabImage" border="0" title="sideBar" alt="sideBar" src="/intranet/images/navbar_saltnpepper/slide-button-active.gif"/></a>
   <div class="filter" id="sidebar">
   <div id="sideBarContentsInner"> 
      <div class="filter-block">
         <div class="filter-title">
            <%= [lang::message::lookup "" intranet-core.Filter_Tickets "Filter Tickets"] %>
         </div>
         <formtemplate id="ticket_filter"></formtemplate>
      </div>
      <hr/>

      <div class="filter-block">
         <div class="filter-title">
            <%= [lang::message::lookup "" intranet-core.New_Ticket "New Ticket"] %>
         </div>
         <formtemplate id="ticket_new"></formtemplate>
      </div>
      <hr/>

<!--
      <div class="filter-block">
         <div class="filter-title">
            <%= [lang::message::lookup "" intranet-core.Admin_Tickets "Admin Tickets"] %>
         </div>
         @admin_html;noquote@
      </div>
-->
      <hr/>


      <%= [im_navbar_tree -label "main"] %>

   </div>
   </div>

   <div class="fullwidth-list" id="fullwidth-list">
      <div id=fullwidth-main>

      <%= [im_box_header $page_title] %>
         <table>
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
         </table>
     <%= [im_box_footer] %>
     </div>

     <div id=fullwidth-components>
	<%= [im_component_bay "right"] %>
     </div>

   </div>

</div>


