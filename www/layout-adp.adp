<%
  # /packages/flexbase/www/layout-adp.adp
  # $Workfile: layout-adp.adp $ $Revision$ $Date$
%>
<master>

<property name="title">@title@</property>
<property name="context">@context@</property>

<p>
#flexbase.lt_This_is_the_list_of_a#
<ul>
<multiple name="attributes">
<li>@attributes.attribute_name@(@attributes.widget@)</li>
</multiple>
</ul>
#flexbase.lt_Remeber_to_also_add_the_core_attributes#
</p>

<p>
#flexbase.lt_If_you_dont_know_how_# <a href="/doc/acs-templating/tagref" target="_blank">#flexbase.documentation#</a>
#flexbase.and_look_at_the# <a href="/doc/acs-templating/demo/#form" target="_blank">#flexbase.examples#</a>
</p>

<formtemplate id="layout-adp"></formtemplate>


