<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context_bar;noquote@</property>

<if @admin_p@ eq 1>
  <div style="float: right;">
    <a href="cadmin/" class="button">#categories.lt_Category_Administrati#</a>
  </div>
</if>

<h3> #categories.lt_Select_Trees_for_brow# </h3>
<listtemplate name="trees"></listtemplate>

<h3> #categories.lt_Search_for_a_category# </h3>
<formtemplate id="search_form"></formtemplate>

