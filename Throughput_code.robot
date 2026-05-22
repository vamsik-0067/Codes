*** Settings ***
Library           SSHLibrary
Library           String
Library           Collections

*** Test Cases ***

RSRP_SWEEP_THROUGHPUT_TEST

    # =====================================================
    # OPEN CONNECTIONS
    # =====================================================

    Open Connection    192.168.203.63    alias=ATT
    Login    oranautomation    oran

    Open Connection    192.168.203.244    alias=UE
    Login    admin    India@123

    Open Connection    192.168.203.139    alias=SERVER
    Login    oranlab    Ranzure@123

    Open Connection    192.168.203.127    alias=CLIENT
    Login    root    mavenir

    # =====================================================
    # TARGET RSRP LIST
    # =====================================================

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

    ${attenuation}=    Set Variable    0

    # =====================================================
    # MAIN LOOP
    # =====================================================

    FOR    ${TARGET_RSRP}    IN    @{TARGET_RSRP_LIST}

        Log
        Log    ==================================================
        Log    TARGET RSRP = ${TARGET_RSRP}
        Log    ==================================================

        ${TARGET_FOUND}=    Set Variable    False

        WHILE    '${TARGET_FOUND}' == 'False'

            # =====================================================
            # SET ATTENUATOR
            # =====================================================

            Switch Connection    ATT

            Log    Setting Attenuation = ${attenuation}

            ${cmd1}=    Set Variable
            ...    curl -X GET "http://192.168.203.78/:01:CHAN:1:2:3:4:SETATT:${attenuation}"

            Write    ${cmd1}

            Sleep    1s

            ${cmd2}=    Set Variable
            ...    curl -X GET "http://192.168.203.78/:02:CHAN:1:2:3:4:SETATT:${attenuation}"

            Write    ${cmd2}

            Sleep    5s

            # =====================================================
            # READ RSRP
            # =====================================================

            Switch Connection    UE

            ${output}=    Execute Command
            ...    powershell -NoProfile -NonInteractive -Command "$sp=New-Object IO.Ports.SerialPort COM7,9600,None,8,one; $sp.DtrEnable=$true; $sp.RtsEnable=$true; $sp.Open(); $sp.Write('AT+CESQ'+[char]13); Start-Sleep 3; Write-Output ($sp.ReadExisting()); $sp.Close()"

            Log    ${output}

            ${line}=    Get Lines Containing String    ${output}    +CESQ:

            ${values}=    Split String    ${line}    ,

            ${CURRENT_RSRP}=    Evaluate    int(${values[5].strip()}) - 140

            Log    Current RSRP = ${CURRENT_RSRP}

            # =====================================================
            # CHECK TARGET WINDOW
            # =====================================================

            ${LOWER_LIMIT}=    Evaluate    ${TARGET_RSRP} - 1
            ${UPPER_LIMIT}=    Evaluate    ${TARGET_RSRP} + 1

            Log    Target Window = ${LOWER_LIMIT} to ${UPPER_LIMIT}

            IF    ${CURRENT_RSRP} >= ${LOWER_LIMIT} and ${CURRENT_RSRP} <= ${UPPER_LIMIT}

                Log    TARGET RSRP ACHIEVED

                ${TARGET_FOUND}=    Set Variable    True

            ELSE

                # =====================================================
                # ATTENUATION ADJUSTMENT
                # =====================================================

                IF    ${CURRENT_RSRP} > ${TARGET_RSRP}

                    Log    Signal Strong -> Increasing Attenuation

                    ${attenuation}=    Evaluate    ${attenuation} + 1

                ELSE

                    Log    Signal Weak -> Decreasing Attenuation

                    ${attenuation}=    Evaluate    ${attenuation} - 1

                END

            END

            # =====================================================
            # SAFETY CHECK
            # =====================================================

            IF    ${attenuation} > 90

                Fail    Unable to achieve target RSRP

            END

            IF    ${attenuation} < 0

                ${attenuation}=    Set Variable    0

            END

        END

        # =====================================================
        # START IPERF SERVER
        # =====================================================

        Switch Connection    SERVER

        ${server_cmd}=    Set Variable
        ...    cmd /c "cd C:\platform-tools-latest-windows\platform-tools && adb shell /data/local/tmp/iperf -s -i 1 -u -t 180 -B 192.168.205.10 -p 6322 -P 5 > C:\Logs\iperf_${TARGET_RSRP}_${attenuation}.txt"

        Start Command    ${server_cmd}

        Log    iPerf Server Started

        Sleep    5s

        # =====================================================
        # START IPERF CLIENT
        # =====================================================

        Switch Connection    CLIENT

        ${iperf_cmd}=    Set Variable
        ...    iperf -c 192.168.205.10 -u -i 1 -l 1350 -b 360m -t 180 -p 6322 -B 192.168.205.2 -P 5

        Log    ${iperf_cmd}

        Start Command    ${iperf_cmd}

        ${iperf_output}=    Read Command Output    timeout=240s

        Log    ${iperf_output}

        Log
        Log    ==================================================
        Log    THROUGHPUT TEST COMPLETED
        Log    ==================================================

        Sleep    10s

    END

    Log
    Log    ==================================================
    Log    COMPLETE RSRP SWEEP FINISHED
    Log    ==================================================
