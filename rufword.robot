*** Settings ***
Library    SSHLibrary
Library    String
Library    Collections

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
    # TARGET RSRP LIST
    # -----------------------------------------

    @{TARGET_RSRP_LIST}=    Create List
    ...    -60
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
    ...    -60

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
            ...    curl -X GET "http://192.168.203.78/:01:CHAN:1:2:3:4:SETATT:-${attenuation1}"

            Execute Command    ${cmd1}

            Sleep    1s

            ${cmd2}=    Set Variable
            ...    curl -X GET "http://192.168.203.78/:02:CHAN:1:2:3:4:SETATT:-${attenuation2}"

            Execute Command    ${cmd2}

            Sleep    5s

            # ---------------------------------
            # DETACH UE
            # ---------------------------------

            Switch Connection    SERVER

            Execute Command
            ...    cd C:\platform-tools-latest-windows\platform-tools && adb shell svc data disable

            Log To Console    UE DETACHED

            Sleep    5s

            # ---------------------------------
            # ATTACH UE
            # ---------------------------------

            Execute Command
            ...    cd C:\platform-tools-latest-windows\platform-tools && adb shell svc data enable

            Log To Console    UE ATTACHED

            Sleep    10s

            # ---------------------------------
            # READ RSRP
            # ---------------------------------

            ${output}=    Execute Command
            ...    cd C:\platform-tools-latest-windows\platform-tools && adb shell dumpsys telephony.registry | findstr ssRsrp

            Log To Console    ${output}

            ${match}=    Get Regexp Matches
            ...    ${output}
            ...    rsrp=(-?\d+)

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

                ${TARGET_FOUND}=    Set Variable    ${True}

            ELSE

                # -----------------------------
                # DIFFERENCE
                # -----------------------------

                ${DIFF}=    Evaluate
                ...    abs(${CURRENT_RSRP} - ${TARGET_RSRP})

                # -----------------------------
                # STEP SIZE
                # -----------------------------

                IF    ${DIFF} > 10

                    ${STEP1}=    Set Variable    10
                    ${STEP2}=    Set Variable    2

                ELSE

                    ${STEP1}=    Set Variable    5
                    ${STEP2}=    Set Variable    1

                END

                # -----------------------------
                # SIGNAL STRONG
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
                    # SIGNAL WEAK
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
        # THROUGHPUT TEST PLACE
        # -------------------------------------

        Log To Console
        ...    RUN THROUGHPUT TEST HERE

    END

    Close All Connections
