<master src="master">
<property name="page_title">@page_title;noquote@</property>
<property name="context_bar">@context_bar;noquote@</property>
<property name="change_locale">f</property>

<p>#categories.code_necessary#</p>
<pre style="border: 1px solid #CCC; background-color: #EEE; padding: 10px;">
set default_locale [lang::system::site_wide_locale]
<multiple name=trees>
<include src="/packages/categories/lib/tree-code" tree_id="@trees.tree_id@">
</multiple>
</pre>
