# -*- coding: utf-8; mode: tcl; tab-width: 4; indent-tabs-mode: nil; c-basic-offset: 4 -*- vim:fenc=utf-8:ft=tcl:et:sw=4:ts=4:sts=4
#
# This portgroup defines a package that contains only dependencies and (optionally) config files.
#
# Usage:
# PortGroup config_package 1.0

categories              config
platforms               darwin
maintainers             mit.edu:sipb-macathena
homepage                http://macathena.mit.edu/

configure               {}
build                   {}
destroot                {}

options config.readme
default config.readme {{This is a configuration package.}}

proc config.meta {} {
    distfiles
    config.readme {${name} for MacAthena

This is a metapackage.  It provides no files, and its only purpose is to cause
the installation of a set of other packages related to a certain task.  We
recommend that you leave this package installed, so that other related packages
that may be added to a future version of this metapackage will be installed as
well.  If you do not want that to happen, you may safely remove this
metapackage.}
}

post-destroot {
    file mkdir ${destroot}${prefix}/share/doc/${name}
    set outfile [open ${destroot}${prefix}/share/doc/${name}/README.macathena "w"]
    puts $outfile [join ${config.readme} "\n"]
    close $outfile
}

options \
    config.files \
    config.file_pairs
option_proc config.files config_files
default config.file_pairs {}

proc config.add_variant {} {
    global config._addedvariant
    if {![info exists config._addedvariant]} {
        variant manual_config description {Skip installing config files} {
            config.readme-append "This config package was installed with +manual_config."
        }
        set config._addedvariant 1
    }
}

pre-destroot {
    if {[exists config.file_pairs]} {
        config.readme-append "" "This config package installed the following configuration files:"
        foreach file [option "config.file_pairs"] {
            lassign $file src dst
            config.readme-append [file join ${prefix} ${dst}]
        }
    }
}

proc config_files {option action args} {
    global filespath
    if {$action ne "set"} {
        return
    }
    if {![variant_isset manual_config]} {
        foreach file [option "config.files"] {
            config.install ${filespath}/${file} ${file}
        }
    }
}

proc config.install {src dst} {
    config.add_variant
    if {![variant_isset manual_config]} {
        if {[string index ${dst} 0] eq "/"} {
            destroot.violate_mtree yes
        }
        config.file_pairs-append [list ${src} ${dst}]
    }
}
pre-destroot {
    foreach file ${config.file_pairs} {
        lassign $file src dst
        set dest [file join ${prefix} ${dst}]
        file mkdir ${destroot}[file dirname ${dest}]
        file copy ${src} ${destroot}${dest}
    }
}
