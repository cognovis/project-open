<master>
<property name="header_stuff"><SCRIPT Language="JavaScript" src="/resources/diagram/diagram/diagram.js"></SCRIPT></property>

<h2>Introduction Diagram v0.2b</h2>
by <a href="mailto:nima.mazloumi@gmx.de">Nima Mazloumi</a>, and with help of <a href="mailto:lutz.tautenhahn@lutanho.net">Lutz Tautenhahn</a>
<p>This package extends the templating system of OpenACS by providing another
builder next to the list and form builder. The diagram builder is very similar
to the list builder. Two differences are important though: The multirow to be
used must me defined bofore <a href="/api-doc/proc-view?proc=template::diagram::create">template::diagram::create</a> is called since the
column names are retrieved dynamically.
</p>
<p>
The diagram builder was developed in a way that it can be extended to use
different engines for the rendering of the diagrams. Currently it is based on
the "Javascript Diagram Builder", v3.3 Lutz Tautenhahn. But other engines
could be integrated in future like GNUPlot.
</p>
<h2>Extending the Diagram Builder</h2>
<p>The rendering is taking place in
the templates defined under resources/diagram/..<br/>. Currently we support
the following types: pie, curve and cockpit. You can customize the way they
render the diagrams by editing the corresponding templates or adding new
ones. Once a template is created you simply pass its name with the -template
switch of <a href="/api-doc/proc-view?proc=template::diagram::create">template::diagram::create</a>.
</p>
</p>
<h2>Examples</h2>
<p>You need to run the <code>diagram-create.sql</code> to view the examples
below. It will create a table with dummy data. You can remove the table again
using <code>diagram-drop.sql</code>.</p>
<p>A detailed example is given in the API Browser. This page also contains
examples for the three diagram types "pie", "curve" and "cockpit". As you can
see the diagrams are beautifully inserted inside the page flow. Also
CSV-Export is possible.
</p>
<a class="button" href="index?csv=1">CSV</a><include src="pie">
<include src="curve">
<include src="cockpit">
<h2>Limitations</h2>
<p>In order to make this builder easier to be extended the Javascript specific
parts have to be removed:
<ul>
<li>Affected are the procs: <code>template::diagram::prepare_value</code>,
<code>template::diagram::update_borders</code> and
<code>template::diagram::set_borders</code> which nead a clean up. Maybe
moving these information into the templates would be best.
<li>Date and Timestamp based values from the database have to be formatted in
a special way. You must use <code>to_char(mydate, 'YYYY,MM,DD[,HH24][,MI][,SS]')</code> in
your sql query to return a meaningful value. As you can see some elements are
optional. For details please view the <code>Date</code> and <code>UTC</code>
objects documentation for JavaScript.
</ul>
</p>
<h2>Future Work</h2>
<p>Not everything available in the Javascript Diagram Builder was fully
integrated. There are many other things that could be done in future as well. Here some ideas:
<ul>
<li>Give support for GNUPlot - a very powerful engine that has support for all
diagram types including world maps...
<li>Allow the definition of scales. Currently a developer would need to touch
the Javascript Library to add new scales types
<li>Add another package depeding on diagrams and portals and allows the definition of a
repository of monitors and associate them with a role. Thus a given user could
select from a extensible list of diagrams and define a user-specific report
page. This would extend OpenACS towards real business intelligence toolkit for
companies, universities and research labs. It would be important though to
extend diagram to use from a pool of data sources like: databases, tcl
scripts, remove web services...
<li>Provide an XoTCL version in order to support different classes of diagrams
and to improve reusablity.
</ul>