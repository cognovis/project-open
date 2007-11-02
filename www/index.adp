<master src="../../intranet-core/www/master">
<property name="title">Wiki</property>
<property name="main_navbar_label">wiki</property>

<div class="filter-list">
   <div class="filter">
      <div class="filter-block">
	 @wiki_component;noquote@
      </div>
   </div>

   <div class="fullwidth-list">
      <%= [im_box_header "Wiki List"] %>
         @page_list;noquote@
      <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>


