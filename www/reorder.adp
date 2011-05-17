<html> 
<head> 
<meta http-equiv="Content-Type" content="text/html; charset=iso-8859-1"> 
	<title>Tree Example</title> 

	<meta http-equiv="Content-Type" content="text/html; charset=utf-8">
	<meta name='generator' lang='en' content='OpenACS version 5.6.0'>
	<link rel='stylesheet' href='/intranet-sencha/css/example.css' type='text/css' media='screen'>
	<script type="text/javascript" src="/intranet-sencha/js/ext-all-debug-w-comments.js"></script> 
	<link rel='stylesheet' href='/intranet-sencha/css/ext-all.css' type='text/css' media='screen'>

	<script type="text/javascript" src="reorder.js"></script> 
</head> 
<body> 
	<h1>Drag and Drop ordering in a TreePanel</h1> 
	<p>This example shows basic drag and drop node moving in a tree. In this implementation there are no restrictions and 
	anything can be dropped anywhere except appending to nodes marked "leaf" (the files).</p> 
	<!-- <p>Drag along the edge of the tree to trigger auto scrolling while performing a drag and drop.</p> --> 
	<p>In order to demonstrate drag and drop insertion points, sorting was <b>not</b> enabled.</p> 
	<p>The data for this tree is asynchronously loaded through a TreeStore and AjaxProxy.</p> 
	<p>The js is not minified so it is readable. See <a href="reorder.js">reorder.js</a>.</p> 
 
	<div id="tree-div"></div> 
</body> 
</html> 

