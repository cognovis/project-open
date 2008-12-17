<master>
<property name="title">@page_title@</property>
<property name="context">#intranet-core.context#</property>
<property name="main_navbar_label">helpdesk</property>
<property name="sub_navbar">@ticket_navbar_html;noquote@</property>

<SCRIPT Language=JavaScript src=/resources/diagram/diagram/diagram.js></SCRIPT>

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

<if @sla_exists_p@>
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
</if>


      <%= [im_navbar_tree -label "main"] %>

   </div>
   </div>

   <div class="fullwidth-list" id="fullwidth-list">

   <table cellspacing=0 cellpadding=0 border=0 width="100%">
   <form action=/intranet-helpdesk/action method=POST>
   <%= [export_form_vars return_url] %>
   <tr valign=top>
   <td>
	<%= [im_box_header $page_title] %>
            <table class=\"list\">
            <%= $table_header_html %>
            <%= $table_body_html %>
            <%= $table_continuation_html %>
            <%= $table_submit_html %>
	    </table>
	<%= [im_box_footer] %>
   </td>
   <td width="<%= $dashboard_column_width %>">
	<%= $dashboard_column_html %>
   </td>
   </tr>
   </form>
   </table>

</div>

