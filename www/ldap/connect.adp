<master src="master">
<property name="title">@page_title@</property>

<input type=hidden name=logo value=1>

<h2>Organization Logo</h2>

<p>
You can configure @po;noquote@ to show your company logo. 
</p><br>

<p>
<input type=file name=logo_file size=40>
</p>

<br>
<p>
You can also enter the url address of your company website.
</p><br>
<input type=text name=logo_url size=40>
</p>


@perl_lines;noquote@

