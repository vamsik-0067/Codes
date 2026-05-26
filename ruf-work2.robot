*** Test Cases ***

RSRP_SWEEP_TEST

    # -----------------------------------------
    # CONNECT ATTENUATOR
    # -----------------------------------------

    Open Connection    192.168.203.63    alias=ATT
    Login    oranautomation    oran

    # -----------------------------------------
    # CONNECT SERVER
    # -----------------------------------------

    Open Connection    192.168.203.139    alias=SERVER
    Login    oranlab    Ranzure@123

    # -----------------------------------------
    # INITIAL UE ATTACH
    # -----------------------------------------

    Switch Connection    SERVER

    Execute Command
    ...    cd C:\\platform-tools-latest-windows\\platform-tools && adb shell cmd connectivity airplane-mode disable

    Log To Console
    ...    UE ATTACHED

    Sleep    20s

    # -----------------------------------------
    # START IPERF SERVER
    # -----------------------------------------

    Execute Command
    ...    start cmd /k "cd C:\iperf && iperf3.exe -s"

    Log To Console
    ...    IPERF SERVER STARTED

    Sleep    5s

    # -----------------------------------------
    # TARGET RSRP LIST
    # -----------------------------------------

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

    # -----------------------------------------
    # INITIAL ATTENUATION
    # -----------------------------------------

    ${attenuation1}=    Set Variable    0
    ${attenuation2}=    Set Variable    0

    # -----------------------------------------
    # MAIN TARGET LOOP
    # -----------------------------------------

    FOR    ${TARGET_RSRP}    IN    @{TARGET_RSRP_LIST}

        Log To Console
        ...    =====================================

        Log To Console
        ...    TARGET RSRP = ${TARGET_RSRP}

        Log To Console
        ...    =====================================

        ${TARGET_FOUND}=    Set Variable    ${False}

        # -------------------------------------
        # START THROUGHPUT CLIENT
        # -------------------------------------

        Switch Connection    SERVER

        Execute Command
        ...    start cmd /k "cd C:\iperf && iperf3.exe -c 192.168.203.139 -t 300 -i 1"

        Log To Console
        ...    THROUGHPUT STARTED

        Sleep    5s

        # -------------------------------------
        # TARGET SEARCH LOOP
        # -------------------------------------

        WHILE    not ${TARGET_FOUND}

            # ---------------------------------
            # APPLY ATTENUATION
            # ---------------------------------

            Switch Connection    ATT

            Log To Console
            ...    CH1 = ${attenuation1}

            Log To Console
            ...    CH2 = ${attenuation2}

            ${cmd1}=    Set Variable
            ...    curl -X GET "http://192.168.203.78/:01:CHAN:1:2:3:4:SETATT:${attenuation1}"

            Execute Command    ${cmd1}

            Sleep    1s

            ${cmd2}=    Set Variable
            ...    curl -X GET "http://192.168.203.78/:02:CHAN:1:2:3:4:SETATT:${attenuation2}"

            Execute Command    ${cmd2}

            Sleep    5s

            # ---------------------------------
            # READ RSRP
            # ---------------------------------

            Switch Connection    SERVER

            ${output}=    Execute Command
            ...    cd C:\\platform-tools-latest-windows\\platform-tools && adb shell dumpsys telephony.registry | findstr ssRsrp

            Log To Console
            ...    ${output}

            ${match}=    Get Regexp Matches
            ...    ${output}
            ...    rsrp=(-?\\d+)

            ${CURRENT_RSRP}=    Fetch From Right
            ...    ${match}[0]
            ...    =

            ${CURRENT_RSRP}=    Convert To Integer
            ...    ${CURRENT_RSRP}

            Log To Console
            ...    CURRENT RSRP = ${CURRENT_RSRP}

            # ---------------------------------
            # TARGET WINDOW
            # ---------------------------------

            ${LOWER_LIMIT}=    Evaluate
            ...    ${TARGET_RSRP} - 1

            ${UPPER_LIMIT}=    Evaluate
            ...    ${TARGET_RSRP} + 1

            # ---------------------------------
            # TARGET ACHIEVED
            # ---------------------------------

            IF    ${CURRENT_RSRP} >= ${LOWER_LIMIT} and ${CURRENT_RSRP} <= ${UPPER_LIMIT}

                Log To Console
                ...    TARGET ACHIEVED

                ${TARGET_FOUND}=    Set Variable
                ...    ${True}

            ELSE

                # -----------------------------
                # DIFFERENCE
                # -----------------------------

                ${DIFF}=    Evaluate
                ...    abs(${CURRENT_RSRP} - ${TARGET_RSRP})

                Log To Console
                ...    DIFF = ${DIFF}

                # -----------------------------
                # DYNAMIC STEP SIZE
                # -----------------------------

                IF    ${DIFF} > 15

                    ${STEP1}=    Set Variable    5
                    ${STEP2}=    Set Variable    3

                ELSE IF    ${DIFF} > 8

                    ${STEP1}=    Set Variable    3
                    ${STEP2}=    Set Variable    2

                ELSE

                    ${STEP1}=    Set Variable    1
                    ${STEP2}=    Set Variable    1

                END

                Log To Console
                ...    STEP1 = ${STEP1}

                Log To Console
                ...    STEP2 = ${STEP2}

                # -----------------------------
                # SIGNAL TOO STRONG
                # -----------------------------

                IF    ${CURRENT_RSRP} > ${TARGET_RSRP}

                    Log To Console
                    ...    SIGNAL TOO STRONG

                    ${attenuation1}=    Evaluate
                    ...    ${attenuation1} + ${STEP1}

                    ${attenuation2}=    Evaluate
                    ...    ${attenuation2} + ${STEP2}

                ELSE

                    # -------------------------
                    # SIGNAL TOO WEAK
                    # -------------------------

                    Log To Console
                    ...    SIGNAL TOO WEAK

                    ${attenuation1}=    Evaluate
                    ...    ${attenuation1} - ${STEP1}

                    ${attenuation2}=    Evaluate
                    ...    ${attenuation2} - ${STEP2}

                END

                # -----------------------------
                # NEGATIVE PROTECTION
                # -----------------------------

                IF    ${attenuation1} < 0
                    ${attenuation1}=    Set Variable    0
                END

                IF    ${attenuation2} < 0
                    ${attenuation2}=    Set Variable    0
                END

                Log To Console
                ...    NEW CH1 = ${attenuation1}

                Log To Console
                ...    NEW CH2 = ${attenuation2}

            END

        END

        # -------------------------------------
        # TARGET COMPLETED
        # -------------------------------------

        Log To Console
        ...    TARGET ${TARGET_RSRP} COMPLETED

        Sleep    10s

    END

    # -----------------------------------------
    # TEST COMPLETED
    # -----------------------------------------

    Log To Console
    ...    RSRP SWEEP TEST COMPLETED
