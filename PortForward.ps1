# The if statement checkes whether the current powershell session is on higher previlage or not
If (-NOT ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole] "Administrator")) { 
    <#comments comming soon#>
    $arguments = "& '" + $myinvocation.mycommand.definition + "'"
    Start-Process powershell -Verb runAs -ArgumentList $arguments
    Break
}

$ports=@(); # initializes a port variable to hold user input in an array format.

do {
    $userInput = (Read-Host "Enter Port No_")   #Prompts the user to input port number and sets to a variable.
    if ($userInput -ne '') {                    #Checks if the user inputed a non-empty number.
        $ports += $userInput;                   #Appends the input to the ports array.
    } #end of do
} until ($userInput -eq '')                     #Checks if nothing is inputed. Terminates the loop if nothing is inputed.

Invoke-Expression "netsh interface portproxy reset";    #Clears any previous port forwards from the system.
if ($ports.Length -eq 0) {                      #Checkes if user has inputed atleast one port number.
    Write-Output "-:No Port Forwarding Job Performed:-" #If no port number then program stops here.
} else {
    #Below $remoteIP captures ip address of the default wsl distro    
    $remoteIP = bash.exe -c "ip add | grep eth0 | grep inet | cut -d ' ' -f 6 | cut -d '/' -f 1"

    #Below $hostIP captures ip address of the hosting windows pc
    $hostIP = (Get-NetIPAddress -InterfaceAlias Ethernet -AddressFamily IPv4).ToString()

    #Below is a loop to perform the forwarding of each port in '$ports'.
    for( $i = 0; $i -lt $ports.length; $i++ ){
        $port = $ports[$i]
        #Below executes the command in "" which is applying port forwarding to the corresponding host and wsl ip addresses.
        Invoke-Expression "netsh interface portproxy add v4tov4 listenport=$port listenaddress=$hostIP connectport=$port connectaddress=$remoteIP";
    }
    #Below checks if any port inputed is 22 and if so prompts the user the status of the service starting.
    if ($ports.IndexOf(22) -ne -1) {
        Write-Host "Starting SSH (port 22)..."
        bash.exe -c "sudo /etc/init.d/ssh start"
    }
    #Below Shows the current forwarded ports and ip addresses.
    Invoke-Expression "netsh interface portproxy show v4tov4";   
}