param(
    [string] $remoteHost,
    [int] $port = 443
     )

# Open the socket, and connect to the computer on the specified port
write-host "`n Connecting to $remoteHost on port $port "
try {
  $socket = new-object System.Net.Sockets.TcpClient($remoteHost, $port)
} catch [Exception] {
  write-host $_.Exception.GetType().FullName
  write-host $_.Exception.Message
  write-host " - Failed to connect.`n"
  exit 1
}

write-host " - Succesfully Connected.`n"
exit 0