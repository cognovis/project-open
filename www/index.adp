<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>
<property name="sub_navbar">@ticket_navbar_html;noquote@</property>

<div class="filter-list">
   <div class="filter">

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

      <div class="filter-block">
         <div class="filter-title">
            <%= [lang::message::lookup "" intranet-core.Admin_Tickets "Admin Tickets"] %>
         </div>
         @admin_html;noquote@
      </div>
      <hr/>


      <%= [im_navbar_tree -label "main"] %>

   </div>

   <div class="fullwidth-list">
      <%= [im_box_header $page_title] %>
         <table>
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
         </table>
     <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>


