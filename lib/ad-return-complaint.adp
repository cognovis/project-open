<master>
  <property name="title">Problem with your input</property>

<p>&nbsp;</p>
<p>
  We had
  <if @exception_count@ gt 1>some problems</if>
  <else>a problem</else>
  with your input:
</p>
<p>&nbsp;</p>

<ul>
  @exception_text;noquote@
</ul>

<p>&nbsp;</p>
<p>
  Please back up using your browser, correct the above <if @exception_count@ gt 1>s</if>, and resubmit your entry.
</p>

<p>
  Thank you.
</p>
