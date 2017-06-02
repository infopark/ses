proc objectChangedCallback {messages} {
    set f [open "|env --unset=LD_LIBRARY_PATH INSTANCE=[app get instanceName] INSTANCE_DIR=[app get instanceDir] ruby [file join [app get scriptDir] serverCmds publish_object_changes.rb]" w]
    foreach m $messages {
        puts $f $m
    }
    close $f
}
