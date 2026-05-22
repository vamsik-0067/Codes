*** Settings ***
Library           SSHLibrary
Library           String
Library           Collections

*** Variables ***
${ATT_IP}         192.168.203.63
${ATT_USER}       oranautomation
${ATT_PASS}       oran

${UE_IP}          192.168.203.244
${UE_USER}        admin
${UE_PASS}        India@123

${ATTENUATOR_IP}      192.168.203.78

${START_ATTEN}        0
${MAX_ATTEN}          90
${ATT_STEP}           1

${TOLERANCE}          1


*** Test Cases ***

RSRP SWEEP WITH THROUGHPUT

    # ---------------------------------
    # Open Connections
    # ---------------------------------

    Open Connection    ${ATT_IP}    alias=ATT
    Login    ${ATT_USER}    ${ATT_PASS}

    Open Connection    ${UE_IP}    alias=UE
    Login    ${UE_USER}    ${UE_PASS}

    # ---------------------------------
    # RSRP Sweep List
    # Forward + Reverse
    # ---------------------------------

    @{TARGET_RSRP_LIST}=    Create List
    ...    -65
    ...    -70
    ...    -75
    ...    -80
    ...    -85
    ...    -90
    ...    -95
    ...    -100
    ...    -105
    ...    -110
    ...    -115
    ...    -120
    ...    -115
    ...    -110
    ...    -105
    ...    -100
    ...    -95
    ...    -90
    ...    -85
    ...    -80
    ...    -75
    ...    -70
    ...    -65

    ${attenuation}=    Set Variable    ${START_ATTEN}

    # ---------------------------------
    # Main Loop
    # ---------------------------------

    FOR    ${TARGET_RSRP}    IN    @{TARGET_RSRP_LIST}

        Log
        Log    ==========================================
        Log    TARGET RSRP = ${TARGET_RSRP}
        Log    ==========================================

        ${TARGET_FOUND}=    Set Variable    False

        WHILE    '${TARGET_FOUND}' == 'False'

            # ---------------------------------
            # Set Attenuator
            # ---------------------------------

            SET ATTENUATOR    ${attenuation}

            # ---------------------------------
            # Wait for RF Stabilization
            # ---------------------------------

            Sleep    5s

            # ---------------------------------
            # Read Current RSRP
            # ---------------------------------

            ${CURRENT_RSRP}=    GET RSRP

            Log    Current RSRP = ${CURRENT_RSRP}
            Log    Current Attenuation = ${attenuation}

            # ---------------------------------
            # Calculate Acceptance Range
            # ---------------------------------

            ${LOWER_LIMIT}=    Evaluate    ${TARGET_RSRP} - ${TOLERANCE}
            ${UPPER_LIMIT}=    Evaluate    ${TARGET_RSRP} + ${TOLERANCE}

            Log    Target Window = ${LOWER_LIMIT} to ${UPPER_LIMIT}

            # ---------------------------------
            # Check Target Match
            # ---------------------------------

            IF    ${CURRENT_RSRP} >= ${LOWER_LIMIT} and ${CURRENT_RSRP} <= ${UPPER_LIMIT}

                Log
                Log    TARGET RSRP ACHIEVED
                Log    Running Throughput Test

                ${TARGET_FOUND}=    Set Variable    True

            ELSE

                Log    Target not reached -> Increasing attenuation

                ${attenuation}=    Evaluate    ${attenuation} + ${ATT_STEP}

            END

            # ---------------------------------
            # Safety Check
            # ---------------------------------

            IF    ${attenuation} > ${MAX_ATTEN}

                Fail    Unable to achieve target RSRP

            END

        END

        # ---------------------------------
        # Throughput Test
        # ---------------------------------

        RUN THROUGHPUT TEST    ${TARGET_RSRP}    ${attenuation}

        Sleep    10s

    END

    Log
    Log    ==========================================
    Log    COMPLETE RSRP SWEEP FINISHED
    Log    ==========================================


*** Keywords ***

SET ATTENUATOR

    [Arguments]    ${attenuation}

    Switch Connection    ATT

    Log    Setting attenuation = ${attenuation}

    # ---------------------------------
    # Module 01
    # ---------------------------------

    ${cmd1}=    Set Variable
    ...    curl -X GET "http://${ATTENUATOR_IP}/:01:CHAN:1:2:3:4:SETATT:${attenuation}"

    Write    ${cmd1}

    Sleep    1s

    # ---------------------------------
    # Module 02
    # ---------------------------------

    ${cmd2}=    Set Variable
    ...    curl -X GET "http://${ATTENUATOR_IP}/:02:CHAN:1:2:3:4:SETATT:${attenuation}"

    Write    ${cmd2}

    Sleep    2s


GET RSRP

    Switch Connection    UE

    ${output}=    Execute Command
    ...    powershell -NoProfile -NonInteractive -Command "$sp=New-Object IO.Ports.SerialPort COM7,9600,None,8,one; $sp.DtrEnable=$true; $sp.RtsEnable=$true; $sp.Open(); $sp.Write('AT+CESQ'+[char]13); Start-Sleep 3; Write-Output ($sp.ReadExisting()); $sp.Close()"

    Log    ${output}

    ${line}=    Get Lines Containing String    ${output}    +CESQ:

    ${values}=    Split String    ${line}    ,

    # CESQ RSRP Formula
    # Actual RSRP = value - 140

    ${rsrp}=    Evaluate    int(${values[5].strip()}) - 140

    Log    Calculated RSRP = ${rsrp}

    RETURN    ${rsrp}


RUN THROUGHPUT TEST

    [Arguments]    ${TARGET_RSRP}    ${attenuation}

    Log
    Log    ==========================================
    Log    STARTING THROUGHPUT TEST
    Log    Target RSRP = ${TARGET_RSRP}
    Log    Attenuation = ${attenuation}
    Log    ==========================================

    # ---------------------------------
    # ADD YOUR THROUGHPUT COMMAND HERE
    # ---------------------------------

    # Example:

    # Execute Command
    # ...    iperf3 -c <server_ip> -t 30

    Sleep    20s

    Log    Throughput Test Completed
