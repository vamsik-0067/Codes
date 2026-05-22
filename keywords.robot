*** Settings ***
Documentation    Suite description
Resource      /home/oranautomation/automation/TIP_Test_Cases/resource_CombaB8.robot

Library   Collections
Library   OperatingSystem
Library   RequestsLibrary
Library   String
Library   SSHLibrary

*** Keywords ***

SSH TO SERVER
    [Arguments]     ${ip_address}    ${username}     ${password}
    Open Connection   ${ip_address}    
    ${log} =       Login           ${username}    ${password}
    Should Contain    ${log}       Last login
    Start Command     pwd
    ${pwd} =          Read Command Output
    Should Match Regexp   ${pwd}     ^/(home/)?[^/]+$

CHECK POD IS RUNNING
    [Arguments]    ${pattern}
    ${output}=      Execute Command    kubectl get pods -A | awk '/${pattern}/ {print $1, $2, $4}'
   
    ${line}=     Fetch From Left     ${output}    \n
 
    Should Not Be Empty    ${line}
    ${parts}=     Split String    ${line}

    ${namespace}=     Get From List     ${parts}     0
    ${podname}=      Get From List     ${parts}     1
    ${status}=      Get From List      ${parts}     2

    ${namespace}=     Get From List     ${parts}     0
    ${podname}=      Get From List     ${parts}     1
    ${status}=      Get From List      ${parts}     2

    IF     '${status}' == 'Running'
        Log    Pod ${podname} in namespace ${namespace} is Running
    ELSE
        Fail   Pod ${podname} in namespace ${namespace} is in ${status} state
    END
    
    RETURN     ${namespace}     ${podname}     ${status}
    


LOGGING INTO POD
     [Arguments]    ${namespace}     ${podname}

     Write     kubectl exec -it -n ${namespace} ${podname} -- bash
     ${output}=    Read    delay=5sec


GET UEIP

    [Arguments]    ${retries}=15     ${delay}=5s
    
    ${ue_ip}=    Set Variable     ${EMPTY}
    
    FOR   ${i}    IN RANGE    ${retries}
    	Log     Attemp ${i+1} to fetch UEIP
	    #${ue_ip}=	Execute Command     powershell -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like '*Cellular*' } | Select-Object -ExpandProperty IPAddress"
        ${ue_ip}=	Execute Command     powershell -Command "Get-NetIPAddress -AddressFamily IPv4 | Where-Object { $_.InterfaceAlias -like '*Cellular*' -and $_.IPAddress -notlike '169.254*' } | Select-Object -ExpandProperty IPAddress"
        ${ue_ip}=     Strip String    ${ue_ip}
        IF    '${ue_ip}' != ''
	    Log    UE IP found: ${ue_ip}
	    Set Global Variable     ${ue_ip}
	    RETURN     ${ue_ip}
	END
	Log    UE IP not Found, retruing after ${delay}
	Sleep    ${delay}
    END

    Fail     UE IP not found after ${retries} retries




Fetching IP from DU pod

    [Arguments]    ${ip_command}    ${namespace}    ${podname}
    Logging Into Pod    ${namespace}    ${podname}
    ${output}=    Read    delay=2sec
    #Set Client Configuration    prompt=#
    #${output}=    Read Until Prompt
    ${output}=    Write    ${ip_command}
    Set Client Configuration    prompt=#
    ${output}=    Read Until Prompt
    ${clean_output}=    String.Replace String Using Regexp
    ...     ${output}
    ...     \\x1b\\[[0-9;]*[A-Za-z]
    ...     
    ${ip}=    Get Line    ${clean_output}    0
    Set Global Variable     ${ip}
    RETURN    ${ip}


EXECUTE UE AT COMMAND
    
    [Arguments]    ${ue_rdp_ip}    ${ue_rdp_username}     ${ue_rdp_password}    ${ue_command}
    Open Connection    ${ue_rdp_ip}
    Login    ${ue_rdp_username}    ${ue_rdp_password}

    Execute Command     ${ue_command}


Login TO UE
    [Arguments]    ${ue_rdp_ip}    ${ue_rdp_username}     ${ue_rdp_password}
    Open Connection    ${ue_rdp_ip}
    Login    ${ue_rdp_username}    ${ue_rdp_password}


    

Reboot RU
    [Arguments]    ${LoginMode}    ${namespace}    ${podname}    ${RU_User_details}    ${RU_password_details}    ${reboot_ru_cmd}

    ${DHCP}=    Fetching IP from DU pod    ${dhcp_ip_command}    ${namespace}    ${podname}
    ${BindIP}=  Fetching IP from DU pod    ${du_ip_command}    ${namespace}    ${podname}
    # Step 1: Login to DU Server
    SSH to Server    ${DU_Server_ip}    ${DU_Username}    ${DU_Password}

    # Step 2: Login into DU pod if required
    ${mode}=    Convert To Lower Case    ${LoginMode}
    ${mode}=    Strip String             ${mode}

    Run Keyword If    '${mode}' == 'pod'
    ...    Logging Into Pod    ${namespace}    ${podname}    

    # Step 3: Fetch IPs AFTER correct login
    

    # Step 4: Build SSH command
    IF    '${mode}' == 'pod'
        ${ssh_cmd}=    Set Variable    ssh -b ${BindIP} ${RU_User_details}@${DHCP}
    ELSE
        ${ssh_cmd}=    Set Variable    ssh ${RU_User_details}@${DHCP}
    END

    # Step 5: SSH to RU
    Write    ${ssh_cmd}
    
    ${status}    ${output}=    Run Keyword And Ignore Error
    ...     Read Until    yes/no

    IF     '${status}' == 'PASS'
        Write   yes
        Read Until   password:
    ELSE
        Run keyword If    'password:' not in '''${output}'''
        ...     Read Until   password:
    END

    #Read Until    password:
    Write    ${RU_password_details}

    Set Client Configuration    timeout=2s    newline=\r

    # Step 6: Reboot RU
    Write    ${reboot_ru_cmd}
    ${output}=    Read    delay=30sec
   

    Set Test Message    RU Reboot successfully


RU STATE IS UP FROM DU POD

    [Arguments]    ${namespace}    ${podname}
    SSH to Server    ${DU_Server_ip}    ${DU_Username}     ${DU_Password}
    Logging Into Pod    ${namespace}    ${podname}
    ${output}=    Read    delay=2sec
    #Set Client Configuration    prompt=#
    #Read Until Prompt

    Write    cli
    ${output}=    Read    delay=5sec
    

    Wait Until Keyword Succeeds
    ...     30 min
    ...     20 sec
    ...     Check RU Operational state


Check RU Operational state
    Write    show eutrancell state all
    Set Client Configuration    prompt=#
    ${output}=    Read Until Prompt
    ${lines}=    Split To Lines    ${output}
    @{cells}=    Create List
    FOR    ${line}     IN    @{lines}
        IF    'Eutran Cell:' in '${line}'
            Append To List    ${cells}    ${line}
        END
    END
    Should Not Be Empty    ${cells}
    ${first_cell}=    Set Variable    ${cells}[0]

    ${state}=    Get Regexp Matches    ${first_cell}    State:\\s+(\\S+)    1
    Should Be Equal    ${state}[0]    operational

    #Log    ${first_cell}

    #Should Not Contain     ${first_cell}     spu-init
    #Should Not Contain     ${first_cell}     pre-op
    #Should Not Contain     ${first_cell}     ready


RU SSH IS UP
    [Arguments]    ${LoginMode}    ${BindIP}    ${RU_User_details}    ${DHCP}    ${RU_password_details}

    ${mode}=    Convert To Lower Case    ${LoginMode}
    ${mode}=    Strip String             ${mode}

    IF    '${mode}' == 'pod'
        ${ssh_cmd}=    Set Variable    ssh -b ${BindIP} ${RU_User_details}@${DHCP} echo OK
    ELSE
        ${ssh_cmd}=    Set Variable    ssh ${RU_User_details}@${DHCP} echo OK
    END

    Write    ${ssh_cmd}

    ${status}    ${output}=    Run Keyword And Ignore Error
    ...     Read Until    yes/no

    IF     '${status}' == 'PASS'
        Write   yes
        Read Until   password:
    ELSE
        Run keyword If    'password:' not in '''${output}'''
        ...     Read Until    password:
    END

    #Read Until    password:
    #Run Keyword If    '${LAST_READ}' != 'OK'
    Write    ${RU_password_details}

    Read Until    OK
    
    

GET CELL BAND SERIAL BY BANDNAME
    
    [Documentation]    Return cell-id, band number, and serial for given band (XML only)
    [Arguments]    ${target_band}
    Set Client Configuration    prompt=#
    Write    grep -E "radio-id>|radio-serial-num>|radio-band-id>" /dskfs/config_du.xml | sed -E 's/.*>([^<]+)<.*/\\1/' | awk '/^[0-9]+$/{c=$0} /^AA/{s=$0} /^band[0-9]+$/{print c, $0, s}'
    ${output}=    Read Until Prompt
    @{lines}=    Split To Lines    ${output}

    ${cell_id}=    Set Variable    ${EMPTY}
    ${band_num}=   Set Variable    ${EMPTY}
    ${serial}=     Set Variable    ${EMPTY}
    ${found}=      Set Variable    ${False}

    FOR    ${line}    IN    @{lines}
        # Skip empty lines
        Continue For Loop If    '${line}' == ''

        # Check if line matches: "<number> band<number> <serial>"
        ${status}    ${msg}=    Run Keyword And Ignore Error
        ...    Should Match Regexp    ${line}    ^[0-9]+\\s+band[0-9]+\\s+[A-Za-z0-9]+$

        Continue For Loop If    '${status}' == 'FAIL'

        ${cell_m}=    Get Regexp Matches    ${line}    ^([0-9]+)
        ${band_m}=    Get Regexp Matches    ${line}    (?<=band)[0-9]+
        ${ser_m}=     Get Regexp Matches    ${line}    ([A-Za-z0-9]+)$

        ${band_num}=    Set Variable    ${band_m[0]}

        IF    '${band_num}' == '${target_band}'
            ${cell_id}=    Set Variable    ${cell_m[0]}
            ${serial}=     Set Variable    ${ser_m[0]}
            ${found}=      Set Variable    ${True}
            Exit For Loop
        END
    END

    IF    not ${found}
        Fail    Band ${target_band} not found in XML
    END

    RETURN    ${cell_id}    ${band_num}    ${serial}

CHECK CELL OPERATIONAL STATUS

    [Arguments]     ${target_cell}
    Set Client Configuration    prompt=#
    ${input}=    Write    cli
    Set Client Configuration    timeout=60sec
    # --------------------------------------------------
    # WAIT CONFIGURATION
    # --------------------------------------------------
    ${timeout}=        Set Variable    1200     # total wait time in seconds
    ${interval}=       Set Variable    10
    ${elapsed}=        Set Variable    0
    ${is_operational}=    Set Variable    False
 
    # --------------------------------------------------
    # POLL UNTIL CELL IS OPERATIONAL
    # --------------------------------------------------
    WHILE    ${elapsed} < ${timeout}
 
        ${input}=     Write    show eutrancell state all
        ${output}=    Read Until Prompt
 
        ${pattern}=    Set Variable
        ...    (?mi)^Eutran\\s+Cell:\\s*${target_cell}\\s+State:\\s*operational\\b
 
        ${is_operational}=    Evaluate
        ...    __import__('re').search(r'''${pattern}''', """${output}""") is not None
 
        IF    ${is_operational}
            Log To Console    ✅ E-UTRAN Cell ${target_cell} is OPERATIONAL
            BREAK
        END
 
        Log To Console
        ...    ⏳ Waiting for E-UTRAN Cell ${target_cell} to become operational...
        ...    Current output:\n${output}
 
        Sleep    ${interval}s
        ${elapsed}=    Evaluate    ${elapsed} + ${interval}
 
    END
 
    IF    not ${is_operational}
        Fail
        ...    ❌ E-UTRAN Cell ${target_cell} did NOT become operational within ${timeout}s.
        ...    \nLast output:\n${output}
    END

SET ATTENUATION BASED ON RADIO CONDITION

    [Arguments]    ${CONDITION}

    # ---------------------------------
    # 1. Select RSRP Range 
    # ---------------------------------

    IF    '${CONDITION}' == 'EXCELLENT'
        ${LOWER}=    Set Variable    -75
        ${UPPER}=    Set Variable     0
    ELSE IF     '${CONDITION}' == 'GOOD'
        ${LOWER}=    Set Variable    -90
        ${UPPER}=    Set Variable    -75
    ELSE IF     '${CONDITION}' == 'FAIR'
        ${LOWER}=    Set Variable     -105
        ${UPPER}=    Set Variable     -90
    ELSE IF    '${CONDITION}' == 'POOR'
        ${LOWER}=    Set Variable    -200
        ${UPPER}=    Set Variable    -105
    ELSE
        Fail    Invalid CONDITION given
    END

    Log    Target RSRP Range = ${LOWER} to ${UPPER}

    # ---------------------------------
    # 2. Initial setup 
    # ---------------------------------

    Open Connection    192.168.203.63    alias=ATT
    Login    oranautomation     oran

    Open Connection    192.168.203.244    alias=UE
    Login     admin    India@123

    ${attenuation}=    Set Variable     95
    ${FINAL_ATTENUATOR}=    Set Variable     NONE

    # ---------------------------------
    # 3. Start Adjustment Loop 
    # ---------------------------------

    WHILE    ${attenuation} >=0
        Log    ------------------------------------
        Log    Setting Attenuation to ${attenuation}

        #set attenuator

        ${current_atten}=    Set Variable    ${attenuation}
        ${cmd}=    Set Variable    curl -X GET "http://192.168.203.78/:01:CHAN:3:4:SETATT:${current_atten}"

        Switch Connection    ATT
        Write    ${cmd}
        Sleep    2sec

        #Read RSRP
        Switch Connection    UE
        ${output}=    Execute Command
        ...    powershell -NoProfile -NonInteractive -Command "$sp=New-Object IO.Ports.SerialPort COM7,9600,None,8,one; $sp.DtrEnable=$true; $sp.RtsEnable=$true; $sp.Open(); $sp.Write('AT+CESQ'+[char]13); Start-Sleep 3; Write-Output ($sp.ReadExisting()); $sp.Close()"
        Log    ${output}

        ${line}=      Get Lines Containing String    ${output}    +CESQ:
        ${values}=    Split String    ${line}    ,
        
        # Convert index to actual RSRP

        ${rsrp}=    Evaluate    int(${values[5].strip()}) - 140

        Log    Calculated RSRP = ${rsrp}
        Log     Target Range = ${LOWER} to ${UPPER}

        # ---------------------------------
        # 4. Check Range 
        # ---------------------------------
            
        IF    ${rsrp} >= ${LOWER} and ${rsrp} <= ${UPPER}
            Log    RSRP within target range

            ${FINAL_ATTENUATOR}=    Set Variable     ${attenuation}
            BREAK
        END

        IF    ${rsrp} < ${LOWER}
            Log    Signal too week -> Decreasing attenuation
            ${attenuation}=    Evaluate    ${attenuation} - 5

        ELSE
            Log    Signal too strong -> Increasing attenuation
            ${attenuation}=    Evaluate    ${attenuation} - 5
        END
    END

    # ---------------------------------
    # 4. Final Validation
    # ---------------------------------
 
    Should Not Be Equal    ${FINAL_ATTENUATOR}    NONE
    Log    Final Fixed Attenuation = ${FINAL_ATTENUATOR}

        
    

    







Set Attenuator
    [Arguments]    ${att_value}

    Switch Connection    ATT
    ${cmd}=    Set Variable    curl -X GET "http://192.168.203.78/:01:CHAN:3:4:SETATT:${att_value}"
    Write    ${cmd}
    Sleep    2s


Get RSRP From UE

    Switch Connection    UE

    ${output}=    Execute Command
    ...    powershell -NoProfile -NonInteractive -Command "$sp=New-Object IO.Ports.SerialPort COM7,9600,None,8,one; $sp.DtrEnable=$true; $sp.RtsEnable=$true; $sp.Open(); $sp.Write('AT+CESQ'+[char]13); Start-Sleep 3; Write-Output ($sp.ReadExisting()); $sp.Close()"

    ${line}=      Get Lines Containing String    ${output}    +CESQ:
    ${values}=    Split String    ${line}    ,

    ${rsrp}=    Evaluate    int(${values[5].strip()}) - 140

    RETURN    ${rsrp}






Set Based On RSRP
    [Arguments]    ${CONDITION}

    # ---------------------------------
    # 1. Select RSRP Range
    # ---------------------------------

    IF    '${CONDITION}' == 'EXCELLENT'
        ${LOWER}=    Set Variable    -75
        ${UPPER}=    Set Variable    0
    ELSE IF    '${CONDITION}' == 'GOOD'
        ${LOWER}=    Set Variable    -90
        ${UPPER}=    Set Variable    -75
    ELSE IF    '${CONDITION}' == 'FAIR'
        ${LOWER}=    Set Variable    -105
        ${UPPER}=    Set Variable    -90
    ELSE IF    '${CONDITION}' == 'POOR'
        ${LOWER}=    Set Variable    -200
        ${UPPER}=    Set Variable    -105
    ELSE
        Fail    Invalid CONDITION given
    END

    Log    Target RSRP Range = ${LOWER} to ${UPPER}

    # ---------------------------------
    # 2. Initial Setup
    # ---------------------------------

    Open Connection    192.168.203.63    alias=ATT
    Login    oranautomation    oran

    Open Connection    192.168.203.244    alias=UE
    Login    admin    India@123

    ${FINAL_ATTENUATOR}=    Set Variable    NONE

    # ---------------------------------
    # 3. Adjustment Loop (FOR instead of WHILE)
    # ---------------------------------

    FOR    ${attenuation}    IN RANGE    95    -1    -5

        Log    ------------------------------------
        Log    Setting Attenuation to ${attenuation}

        ${cmd}=    Set Variable
        ...    curl -X GET "http://192.168.203.78/:01:CHAN:3:4:SETATT:${attenuation}"

        Switch Connection    ATT
        Write    ${cmd}
        Sleep    2s

        # Read RSRP
        Switch Connection    UE
        ${output}=    Execute Command
        ...    powershell -NoProfile -NonInteractive -Command "$sp=New-Object IO.Ports.SerialPort COM7,9600,None,8,one; $sp.DtrEnable=$true; $sp.RtsEnable=$true; $sp.Open(); $sp.Write('AT+CESQ'+[char]13); Start-Sleep 3; Write-Output ($sp.ReadExisting()); $sp.Close()"

        Log    ${output}

        ${line}=    Get Lines Containing String    ${output}    +CESQ:
        ${values}=    Split String    ${line}    ,
        ${rsrp}=    Evaluate    int(${values[5].strip()}) - 140

        Log    Calculated RSRP = ${rsrp}
        Log    Target Range = ${LOWER} to ${UPPER}

        # Check Range
        IF    ${rsrp} >= ${LOWER} and ${rsrp} <= ${UPPER}
            Log    RSRP within target range
            ${FINAL_ATTENUATOR}=    Set Variable    ${attenuation}
            Exit For Loop
        END

    END

    # ---------------------------------
    # 4. Final Validation
    # ---------------------------------

    Should Not Be Equal    ${FINAL_ATTENUATOR}    NONE
    Log    Final Fixed Attenuation = ${FINAL_ATTENUATOR}
    RETURN    ${FINAL_ATTENUATOR}




hello welocome to the new file
