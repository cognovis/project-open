<master>
<property name="title">@page_title@</property>
<property name="context">@context;noquote@</property>
<form method=GET action=search>
  <small>
    <a href=@url_advanced_search@>#intranet-search-pg.Advanced_Search#</a>
    <br>
    <input type=text name=q size=31 maxlength=256 value="@query@">
    <input type=submit value="#intranet-search-pg.Search#" name=t>
  </small>
</form>
<if @t@ eq "Search">
  <i>#intranet-search-pg.lt_Tip_In_most_browsers_#</i><br><br>
</if>

	<if @and_queries_notice_p@ eq 1>
      	  <font color=6f6f6f>
          #intranet-search-pg.The#
          [<a href=help/basics#and>#intranet-search-pg.details#</a>]<br>
        </font>
	</if>
	<if @nstopwords@ eq 1>
        <font color=6f6f6f>
          #intranet-search-pg.lt_bstopwordsb_is_a_very#
          [<a href=help/basics#stopwords>#intranet-search-pg.details#</a>]<br>
        </font>
	</if>
	<if @nstopwords@ gt 1>
      	  <font color=6f6f6f>
          #intranet-search-pg.lt_The_following_words_a# <b>@stopwords@</b>.
          [<a href=help/basics#stopwords>#intranet-search-pg.details#</a>]<br>
      	  </font>
	</if>


@result_html;noquote@

<if @count@ eq 0>
  Your search - <b>@query@</b> - did not match any documents.
  <br>#intranet-search-pg.lt_No_pages_were_found_c#<b>@query@</b>".
  <br><br>#intranet-search-pg.Suggestions#
  <ul>
    <li>#intranet-search-pg.lt_Make_sure_all_words_a#
    <li>#intranet-search-pg.lt_Try_different_keyword#
    <li>#intranet-search-pg.lt_Try_more_general_keyw#
    <if @nquery@ gt 2>
      <li>#intranet-search-pg.Try_fewer_keywords#
    </if>
  </ul>
</if>
<else>
  <table width=100% bgcolor=3366cc border=0 cellpadding=3 cellspacing=0>
    <tr><td>
      <font color=white>
        #intranet-search-pg.Searched_for_query#
      </font>
    </td><td align=right>
      <font color=white>
        #intranet-search-pg.Results# <b>@low@-@high@</b> #intranet-search-pg.of_about# <b>@count@</b>#intranet-search-pg.________Search_took# <b>@elapsed@</b> #intranet-search-pg.seconds# 
      </font>     
    </td></tr>
  </table>
  <br clear=all>
</else>

<if @from_result_page@ lt @to_result_page@>
  <center>

    <small>#intranet-search-pg.Result_page#</small>

    <if @from_result_page@ lt @current_result_page@>
      <small><a href=@url_previous@><font color=0000cc><b>#intranet-search-pg.Previous#</b></font></a></small>
    </if>
    &nbsp;@choice_bar;noquote@&nbsp;
    
    <if @current_result_page@ lt @to_result_page@>
	<small><a href=@url_next@><font color=0000cc><b>#intranet-search-pg.Next#</b></font></a></small>
    </if>
  </center>
</if>
<if @count@ gt 0>
  <center>
    <table border=0 cellpadding=3 cellspacing=0>
      <tr><td nowrap>
        <form method=GET action=search>
          <center>
            <small>
              <input type=text name=q size=31 maxlength=256 value="@query@">
              <input type=submit value=Search>
            </small>
          </center>
        </form>
      </td></tr>
    </table>
  </center>

  <if @stw@ not nil>
    <center>
      <font size=-1>#intranet-search-pg.lt_Try_your_query_on_stw#</font></center>
    </center>
  </if>
</if>
