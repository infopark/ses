proc objectChangedCallback {messages} {
  add_to_redis $messages "index_[app get instanceName]" "Infopark::SES::Indexer"
}

proc add_to_redis { messages QUEUE CLASS } {
  set NAMESPACE "resque"
  append protocoll "SADD ${NAMESPACE}:queues ${QUEUE}\r\n"
  foreach m $messages {
    append protocoll "RPUSH ${NAMESPACE}:queue:${QUEUE} \"{\\\"class\\\":\\\"${CLASS}\\\",\\\"args\\\":\\\"${m}\\\"}\"\r\n"
  }

  # logMessage 1 "sending to redis:\n $protocoll"
  set redis [ open "|redis-cli --pipe" w ]
  puts -nonewline $redis $protocoll
  close $redis
}

