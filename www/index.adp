  <master>
    <property name=title>Surveys</property>
    <property name="context">@context;noquote@</property>

    <if @surveys:rowcount@ eq 0>
      <em>No surveys active</em>
    </if>
    <else>
      <ul>
        <multiple name=surveys>
          <li><a href="one?survey_id=@surveys.survey_id@">@surveys.name@</a></li>
        </multiple>
      </ul>
    </else>
