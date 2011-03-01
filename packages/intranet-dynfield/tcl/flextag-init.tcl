
#
# Author: Juanjo Ruiz (juanjoruizx@yahoo.es)
#
# $Id: flextag-init.tcl,v 1.2 2005/06/10 11:56:15 cvs Exp $
#

template_tag formlabel { params } {

  set id [template::get_attribute formwidget $params id]

  # get any additional HTML attributes specified by the designer
  set tag_attributes [template::util::set_to_list $params id]

  template::adp_append_string \
	  "\[template::element render_label \${form:id} $id { $tag_attributes } \]"
}

template_tag formhelptext { chunk params } {

  set id [template::get_attribute formwidget $params id]

  # get any additional HTML attributes specified by the designer
  set tag_attributes [template::util::set_to_list $params id]

  # insert the adp code that is between the tags
  template::adp_append_code \
          "if {!\[empty_string_p \[template::element render_help \${form:id} $id { $tag_attributes } \]\]} {
      append __adp_output \"$chunk  \[template::element render_help \${form:id} $id { $tag_attributes } \]\"
  }"
}
