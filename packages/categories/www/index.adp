<master>
<property name="title">@page_title;noquote@</property>
<property name="context">@context_bar;noquote@</property>

<if @admin_p@ eq 1>
  <div style="float: right;">
    <a href="cadmin/" class="button">Category Administration</a>
  </div>
</if>

<h3> Select Trees for browsing </h3>
<listtemplate name="trees"></listtemplate>

<h3> Search for a category </h3>
<formtemplate id="search_form"></formtemplate>
