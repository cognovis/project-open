<master>
<property name=title>Surveys</property>
<property name="context">@context;noquote@</property>

<if @surveys:rowcount@ eq 0>
	<em>No surveys active</em>
</if>
<else>
	<ul>
	<multiple name=surveys>
		<li><a href="@surveys.survey_url;noquote@">@surveys.name@</a></li>
	</multiple>
	</ul>
</else>
