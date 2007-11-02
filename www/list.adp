<master src="../../intranet-core/www/master">
<property name="title">@page_title;noquote@</property>
<property name="main_navbar_label">finance</property>
<property name="sub_navbar">@sub_navbar;noquote@</property>

<div class="filter-list">
   <div class="filter">
      <div class="filter-block">
         <div class="filter-title">
	    #intranet-cost.Filter_Documents#
         </div>
	 @filter_html;noquote@
      </div>
      <if @new_document_menu@ ne "">
         <div class="filter-block">
            <div class="filter-title">
               #intranet-cost.lt_Cost_Item_Administrat#
            </div>
            <ul>
               @new_document_menu;noquote@
           </ul>
         </div>
      </if>
   </div>

   <div class="fullwidth-list">
      <%= [im_box_header $page_title] %>

      <form action="/intranet-cost/costs/cost-action" method="POST">
         <%= [export_form_vars company_id cost_id return_url]%>
         <table width=100% cellpadding=2 cellspacing=2 border=0>
            @table_header_html;noquote@
            @table_body_html;noquote@
            @table_continuation_html;noquote@
            @button_html;noquote@
         </table>
      </form>

      <%= [im_box_footer] %>
   </div>
   <div class="filter-list-footer"></div>

</div>




