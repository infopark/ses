
proc objectChangedCallback {messages} {
    set f [open "|env INSTANCE=[app get instanceName] ruby [app get scriptDir]/serverCmds/publish_object_changes.rb" w]
    foreach m $messages {
        puts $f $m
    }
    close $f
}
