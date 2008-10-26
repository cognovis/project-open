<!-- packages/intranet-confdb/www/index.adp -->
<!-- @author Frank Bergmann (frank.bergmann@project-open.com) -->
<master src="../../intranet-core/www/master">
<property name="title">@page_title@</property>
<property name="context">@context_bar@</property>
<property name="main_navbar_label">conf_items</property>


<div class="filter-list">
<a id="sideBarTab" href="#"><img id="sideBarTabImage" border="0" title="sideBar" alt="sideBar" src="/intranet/images/navbar_saltnpepper/slide-button-active.gif"/></a>
  <div class="filter" id="sidebar">
<div id="sideBarContentsInner"> 
    <div class="filter-block">
      <div class="filter-title">
	<%= [lang::message::lookup "" intranet-confdb.Filter_Items "Filter Items"] %>
      </div>

      <formtemplate id=@form_id@></formtemplate>
    </div>
    <hr>

    <div class="filter-block">
      <div class="filter-title">
        #intranet-core.Admin_Links#
      </div>
      @admin_links;noquote@
    </div>

    <div class="filter-block">
      <%= [im_navbar_tree -label "main"] %>
    </div>

  </div>
</div>
  <div class="fullwidth-list" id="fullwidth-list">
    <%= [im_box_header $page_title] %>
    <listtemplate name="@list_id@"></listtemplate>
    <%= [im_box_footer] %>
  </div>

</div>





