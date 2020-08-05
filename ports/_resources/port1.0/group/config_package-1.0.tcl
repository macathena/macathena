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

distfiles

configure               {}
build                   {}
destroot                {}

options config.readme
default config.readme {{This is a configuration package.}}

proc config.meta {} {
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

options config.files
option_proc config.files config_files

proc config_files {option action args} {
    if {$action ne "set"} {
        return
    }
    variant manual_config description {Skip installing config files} {
        config.readme-append "This config package was installed with +manual_config."
    }
    if {![variant_isset manual_config]} {
        config.readme-append "This config package installed the following files:"
        # TODO: Support generated config files
        foreach file [option "config.files"] {
            if {[string index $file 0] eq "/"} {
                destroot.violate_mtree yes
            }
        }
        pre-destroot {
            foreach file [option "config.files"] {
                set dest [file join ${prefix} ${file}]
                config.readme-append ${dest}
                file mkdir ${destroot}[file dirname ${dest}]
                file copy ${filespath}${file} ${destroot}${dest}
            }
        }
    }
}
