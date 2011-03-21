<%
  # /packages/intranet-dynfield/www/layout-position.adp
  # $Workfile: layout-position.adp $ $Revision: 1.6 $ $Date: 2008/03/24 22:35:57 $
%>
<master src="master">

<h1>@page_url@ Layout for @object_type@</h1>
<property name="title">@title@</property>
<property name="context">@context;noquote@</property>

<p>
<listtemplate name="attrib_list"></listtemplate>
</p>

<if @page.layout_type@ eq "relative">
<p>
#intranet-dynfield.Hint_Remember_that_yo#
</p>
</if>
