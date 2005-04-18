ad_library {
    Do initialization at server startup for the acs-lang package.

    @creation-date 23 October 2000
    @author Peter Marklund (peter@collaboraid.biz)
    @cvs-id $Id: acs-lang-init.tcl,v 1.1 2005/04/18 19:25:53 cvs Exp $
}

# Cache I18N messages in memory for fast lookups
lang::message::cache
