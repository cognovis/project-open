<master>
  <property name="title">@page_title;noquote@</property>
  <property name="context">@context;noquote@</property>

<h3>The server has been shut down</h3>
<p> Normally, it should come back up by itself after a minute or so. </p>
<br>&nbsp;<br>

<if @windows_p@>
	<font color=red><b>
	On Windows, if @po;noquote@ doesn't start automatically, as it should:
	</b></font>
	<br>&nbsp;<br>Either:<br>
	<ul>
	<li>Please restart your computer.<br>
	    @po;noquote@ should start automatically.
	</ul>
	<br>
	
	Or:
	<ul>
	<li>Go to All Programs -&gt; @po;noquote@
	<li>Execute "Start @po;noquote@".<br>
	    On Windows Vista and higher you need to right-click <br>
	    "Start @po;noquote@" and choose "Run as Administrator".
	</ul>
	<br>&nbsp;<br>
</if>

<p> If @po;noquote@ still doesn't start, please check your server error log
or contact your system administrator. </p>

