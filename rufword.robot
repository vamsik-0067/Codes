RSRP_SWEEP_THROUGHPUT_TEST

    # =====================================================
    # OPEN CONNECTIONS
    # =====================================================

    Open Connection    192.168.203.63    alias=ATT
    Login    oranautomation    oran

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
            # READ RSRP USING ADB
            # =====================================================

            Switch Connection    SERVER

            ${output}=    Execute Command
            ...    cd C:\\platform-tools-latest-windows\\platform-tools && adb shell dumpsys telephony.registry | findstr ssRsrp

            Log    ${output}

            ${match}=     Get Regexp Matches    ${output}     rsrp=(-?\\d+)
            Log     ${match}
            
            ${CURRENT_RSRP}=    Fetch From Right     ${match[0]}    =
            ${CURRENT_RSRP}=     Convert To Integer     ${CURRENT_RSRP}
            
            Log     Current RSRp = ${CURRENT_RSRP}

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
        ...    cmd /c "cd C:\\platform-tools-latest-windows\\platform-tools && adb shell /data/local/tmp/iperf -s -i 1 -u -t 180 -B 192.168.205.10 -p 6322 -P 5 > C:\\Logs\\iperf_${TARGET_RSRP}_${attenuation}.txt"

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

        
        Log    ==================================================
        Log    THROUGHPUT TEST COMPLETED
        Log    ==================================================

        Sleep    10s

    END

    
    Log    ==================================================
    Log    COMPLETE RSRP SWEEP FINISHED
    Log    ==================================================
     
	
