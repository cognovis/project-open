<%
  # /packages/flexbase/www/layout-position.adp
  # $Workfile: layout-position.adp $ $Revision$ $Date$
%>
<master>

<property name="title">@title@</property>
<property name="context">@context;noquote@</property>

<p>
<listtemplate name="attrib_list"></listtemplate>
</p>

<if @page.layout_type@ eq "relative">
<p>
#flexbase.lt_Hint_Remember_that_yo#
</p>
</if>
