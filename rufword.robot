KEYWORD SSHLibrary . Switch Connection   SERVER
00:00:00.240KEYWORD ${output} =   SSHLibrary . Execute Command   cd C:\\platform-tools-latest-windows\\platform-tools && adb shell dumpsys telephony.registry | findstr ssRsrp
00:00:00.001KEYWORD BuiltIn . Log   ${output}
Documentation:	
Logs the given message with the given level.

Start / End / Elapsed:	20260522 20:44:41.487 / 20260522 20:44:41.488 / 00:00:00.001
20:44:41.487	INFO	    mSignalStrength=SignalStrength:{mCdma=CellSignalStrengthCdma: cdmaDbm=2147483647 cdmaEcio=2147483647 evdoDbm=2147483647 evdoEcio=2147483647 evdoSnr=2147483647 level=0,mGsm=CellSignalStrengthGsm: rssi=2147483647 ber=2147483647 mTa=2147483647 mLevel=0,mWcdma=CellSignalStrengthWcdma: ss=2147483647 ber=2147483647 rscp=2147483647 ecno=2147483647 level=0,mTdscdma=CellSignalStrengthTdscdma: rssi=2147483647 ber=2147483647 rscp=2147483647 level=0,mLte=CellSignalStrengthLte: rssi=-51 rsrp=-65 rsrq=-6 rssnr=30 cqiTableIndex=2147483647 cqi=2147483647 ta=2147483647 level=4 parametersUseForLevel=0,mNr=CellSignalStrengthNr:{ csiRsrp = 2147483647 csiRsrq = 2147483647 csiCqiTableIndex = 2147483647 csiCqiReport = [] ssRsrp = 2147483647 ssRsrq = 2147483647 ssSinr = 2147483647 level = 0 parametersUseForLevel = 0 },primary=CellSignalStrengthLte}
00:00:00.001KEYWORD ${line} =   String . Get Lines Containing String   ${output}    ssRsrp
Documentation:	
Returns lines of the given string that contain the pattern.

Start / End / Elapsed:	20260522 20:44:41.488 / 20260522 20:44:41.489 / 00:00:00.001
20:44:41.488	INFO	1 out of 1 lines matched.	
20:44:41.488	INFO	${line} =     mSignalStrength=SignalStrength:{mCdma=CellSignalStrengthCdma: cdmaDbm=2147483647 cdmaEcio=2147483647 evdoDbm=2147483647 evdoEcio=2147483647 evdoSnr=2147483647 level=0,mGsm=CellSignalStrengthGsm: r...	
00:00:00.001KEYWORD ${values} =   String . Split String   ${line}    =
00:00:00.002KEYWORD ${CURRENT_RSRP} =   String . Strip String   ${values[1]}
00:00:00.001KEYWORD ${CURRENT_RSRP} =   BuiltIn . Convert To Integer   ${CURRENT_RSRP}
Documentation:	
Converts the given item to an integer number.

Start / End / Elapsed:	20260522 20:44:41.492 / 20260522 20:44:41.493 / 00:00:00.001
20:44:41.492	FAIL	'SignalStrength:{mCdma' cannot be converted to an integer: ValueError: invalid literal for int() with base 10: 'signalstrength:{mcdma'
