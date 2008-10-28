<!-- packages/intranet-confdb/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">milestones</property>

<div class="filter-list">
<a id="sideBarTab" href="#"><img id="sideBarTabImage" border="0" title="sideBar" alt="sideBar" src="/intranet/images/navbar_saltnpepper/slide-button-active.gif"/></a>
   <div class="filter" id="sidebar">
      <div class="filter-block">
         <div class="filter-title">
	    <%= [lang::message::lookup "" intranet-milestone.Filter_Milestones "Filter Milestones"] %>
         </div>
         <formtemplate id=@form_id@></formtemplate>
      </div>

      <hr/>
      <div class="filter-block">
         <div class="filter-title">
	        #intranet-core.Admin_Links#
         </div>
         @admin_links;noquote@
      </div>

      <%= [im_navbar_tree -label "main"] %>

   </div>
</div>
   <div class="fullwidth-list" id="fullwidth-list">
	 @page_html;noquote@
   </div>
   <div class="filter-list-footer"></div>

</div>


<if 0>
<listtemplate name="@list_id@"></listtemplate>
</if>


