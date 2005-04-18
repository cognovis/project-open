<html>
  <head>
  <title>Package Documentation</title>
  </head>
  <body bgcolor="#FFFFFF">
  <h1>Package Documentation</h1>
<hr>

  <h2>SQL package documentation browser</h2>

  <formtemplate id="func"></formtemplate>

  <if @procs:rowcount@ gt 0>
    <h3>Procedures and Functions</h3>
    <table border=0 cellspacing=3 cellpadding=0>
    <multiple name=procs>
      <tr><th>@procs.type@</th><td>
      <if @procs.name@ eq @proc_name@>
        <b>@procs.name@</b>
      </if>
      <else>
        <a href="@url_stub@package_name=@package_name@&proc_name=@procs.name@">
           @procs.name@
        </a>
      </else>
      </td></tr>
    </multiple>
    </table>
  </if>  

  <if @tags.name@ not nil>
    <br>
    <hr>

    <h2>@tags.type@ @tags.name@</h2>

    <p>@tags.header@</p>

    <table cellpadding=3 cellspacing=0 border=0>
      <if @tags.author@ not nil>
        <tr><th align=left>Author:</th><td align=left>@tags.author@</td></tr> 
      </if>
      <if @tags.return@ not nil>
        <tr><th align=left>Returns:</th><td align=left>@tags.return@</td></tr>
      </if>
      <tr><th align=left colspan=2>Parameters:</th><tr>
      <tr><td align=left colspan=2>
        <if @params:rowcount@ gt 0>
          <blockquote><table border=0 cellpadding=0 cellspacing=1>
            <multiple name=params>
              <tr><th align=right valign=top>@params.name@:</th>
                  <td>&nbsp;&nbsp;</td><td>@params.value@</td></tr>
            </multiple>
          </table></blockquote>
        </if>
        <else>
          <i>No parameters</i>
        </else></td>
      </tr>
      <tr><th align=left colspan=2>Declaration:</th></tr>
      <tr align=left><td colspan=2 align=left>
<pre><tt>
@code@
</tt></pre>
      </td></tr>
      <if @tags.see@ not nil>
        <tr><th align=left valign=top>See Also:</th><td>@tags.see@</td></tr>
      </if>
    </table>
  </if>      

<hr>
</body>
</html>
