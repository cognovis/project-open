ad_library {

    This file includes various hacks to make OpenACS work on Windows.
    Replaces the TCL exec command on Windows, allowing exec to be called with unix-y arguments.
    <OL>
      <LI> If the program to be executed starts with "/", "/cygwin" is prepended.
           If you want to specify an absolute path to the executable, use the drive letter
           or double backslashes.
      <LI> If stderr is being redirected to /dev/null, it actually gets redirected to nul:
      <LI> This didn't work in early AOLserver 4.0 beta builds as rename was broken.
    </OL>

    @author jrasmuss@mle.ie

}

global tcl_platform 
if { ![string match $tcl_platform(platform) "windows"] } {
    ns_log notice "Running on Linux - Disabling exec hack"
    return
}
ns_log notice "Running on Windows - Enabling exec hack"

rename ::exec ::exec_orig

proc exec {args} {
    set procname [lindex $args 0]
    set args [lrange $args 1 end]
    if {[string index $procname 0] == "/"} {
        set procname "C:/ProjectOpen/cygwin${procname}"
    } else {
##        regsub -all {\\\\} $procname {/} procname ;# Correct?
##        regsub -all {\\} $procname {/} procname
    }

    for {set i 0} {$i < [llength $args]} {incr i} {
        if {[string match [lindex $args $i] "2>/dev/null"]} {
            set args [lreplace $args $i $i "2>nul"]
        }
    }
    set cmd "::exec_orig $procname $args"
    return [eval $cmd]
}
