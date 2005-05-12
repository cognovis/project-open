<master>
<property name="title">#intranet-search-pg.Advanced_Search#</property>
<property name="context">"advanced search"</property>

<form method=GET action=search>
<input type=text name=q size=41 maxlength=256 value="@q@">
<input type=submit value="Search" name=t>
<br>
#intranet-search-pg.Date_Range#
<select name=dfs>
  <option value=all> #intranet-search-pg.anytime#
  <option value=m3> #intranet-search-pg.past_3_months#
  <option value=m6> #intranet-search-pg.past_6_months#
  <option value=y1> #intranet-search-pg.past_year#
</select>
#intranet-search-pg.nbspDisplay#
<select name=num>
 <option value=10 <if @num@ eq 10>#intranet-search-pg.selected#</if>>10 #intranet-search-pg.results#
 <option value=20 <if @num@ eq 20>#intranet-search-pg.selected#</if>>20 #intranet-search-pg.results#
 <option value=30 <if @num@ eq 30>#intranet-search-pg.selected#</if>>30 #intranet-search-pg.results#
 <option value=50 <if @num@ eq 50>#intranet-search-pg.selected#</if>>50 #intranet-search-pg.results#
 <option value=100 <if @num@ eq 100>#intranet-search-pg.selected#</if>>100 #intranet-search-pg.results#
</select>
</form>

