# HEAD procedures for the ArsDigita Templating System

namespace eval template::head {}

ad_proc -public template::head::add_css { 
    {-href "" }
    {-media "" }
} {
    Compatibility-procs with procs from OpenACS 5.4
} {
    # Do nothing
}


ad_proc -public template::head::add_javascript { 
    {-src "" }
} {
    Compatibility-procs with procs from OpenACS 5.4
} {
    # Do nothing
}

