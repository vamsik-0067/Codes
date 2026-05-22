nitiate THroughput

    Open Connection   192.168.203.139
    ${log} =       Login           oranlab    Ranzure@123
    Log    ${log}
    ${output} =    Start Command     cd C:\\platform-tools-latest-windows\\platform-tools && .\\adb shell "/data/local/tmp/iperf -s -i 1 -u -t 180 -B ${ip} -p 6322 -P 5"> C:\\Logs\\hello_111.txt
    
    Open Connection   192.168.203.127
    ${log} =       Login           root    mavenir
    Should Contain    ${log}       Last login
    Start Command     pwd
    ${pwd} =          Read Command Output
    Should Be Equal   ${pwd}    /root
   # ${iperf_command}=    Set Variable    
   # Log    ${iperf_command}
    ${iperf}=    Execute Command    iperf -c ${ip} -u -i 1 -l 1350 -b 360m -t 180 -p 6322 -B 192.168.205.2 -P 5
    ${output}=     Read    delay=120sec
    #Set Client Configuration     prompt=#
    #${output}=     Read Until Prompt
    Log    ${iperf}
    #et Test Message    Initiating Dowlink Throughput with 200Mbps
