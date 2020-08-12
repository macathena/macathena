namespace eval portfetch::mirror_sites { }
global os.platform os.major archivefetch_pubkeys
set portfetch::mirror_sites::sites(macathena_archives) https://macathena.mit.edu/dist/port_archives/:nosubdir
set portfetch::mirror_sites::archive_type(macathena_archives) tbz2
set portfetch::mirror_sites::archive_prefix(macathena_archives) /opt/local
set portfetch::mirror_sites::archive_frameworks_dir(macathena_archives) /opt/local/Library/Frameworks
set portfetch::mirror_sites::archive_applications_dir(macathena_archives) /Applications/MacPorts
if {${os.platform} eq "darwin" && ${os.major} >= 10} {
    set portfetch::mirror_sites::archive_cxx_stdlib(macathena_archives) libc++
} else {
    set portfetch::mirror_sites::archive_cxx_stdlib(macathena_archives) libstdc++
}
if {${os.platform} eq "darwin" && ${os.major} <= 12} {
    set portfetch::mirror_sites::archive_delete_la_files(macathena_archives) no
} else {
    set portfetch::mirror_sites::archive_delete_la_files(macathena_archives) yes
}

set pubkeypath [file join [file dirname $mirrorfile] "macathena-pubkey.pem"]
if {[lsearch $archivefetch_pubkeys $pubkeypath] < 0} {
    lappend archivefetch_pubkeys $pubkeypath
}
#ui_debug "archivefetch_pubkeys = ${archivefetch_pubkeys}"
