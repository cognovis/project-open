# Procedures for assembling and manipulationg search keywords

namespace eval search {}

ad_proc -public search::intermedia_keywords { keywords args } {

    Convert a list of keywords, such as "rat fish bird"
    into an Intermedia search clause of the form
    %rat%, %fish%, %bird%
    If the -within varname option is specified, use the within clause
    In the future, do something so that the scoring is consistent

} {

  template::util::get_opts args

  set word_list [split $keywords " "]

  set inter_clause ""
  set the_or ""
  foreach word $word_list {
    append inter_clause "${the_or}%[string tolower $word]%" 
    if { ![template::util::is_nil opts(within)] } {
      append inter_clause " within \$varname"
    }   
    set the_or ","
  }

  return $inter_clause
}
