If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) {

    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

$ports=@();

do {
    $userInput = (Read-Host "Enter Port No_")
    if ($userInput -ne '') {
        $ports += $userInput;
    }
} until ($userInput -eq '')

Invoke-Expression "netsh interface portproxy reset";
if ($ports.Length -eq 0) {
    Write-Output "-:No Port Forwarding Job Performed:-"
} else {
    $remoteIP = bash.exe -c "ip add | grep eth0 | grep inet | cut -d ' ' -f 6 | cut -d '/' -f 1"
    $hostIP = (Get-NetIPAddress -InterfaceAlias Ethernet -AddressFamily IPv4).ToString()

    for( $i = 0; $i -lt $ports.length; $i++ ){

        $port = $ports[$i];
        Invoke-Expression "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$hostIP connectport=$port connectaddress=$remoteIP";
    }
    if ($ports.IndexOf(22) -ne -1) {
        Write-Host "Starting SSH (port 22)..."
        bash.exe -c "sudo /etc/init.d/ssh start"
    }
    Invoke-Expression "netsh interface portproxy show v4tov4";   
}