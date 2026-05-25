UE Attach                                                             ....UE IP =
UE Attach                                                             | PASS |
------------------------------------------------------------------------------
RSRP_SWEEP_TEST                                                       .......=====================================
TARGET RSRP = -60
=====================================
CH1 = 0
CH2 = 0
UE DETACHED
UE ATTACHED
    mSignalStrength=SignalStrength:{mCdma=CellSignalStrengthCdma: cdmaDbm=2147483647 cdmaEcio=2147483647 evdoDbm=2147483647 evdoEcio=2147483647 evdoSnr=2147483647 level=0,mGsm=CellSignalStrengthGsm: rssi=2147483647 ber=2147483647 mTa=2147483647 mLevel=0,mWcdma=CellSignalStrengthWcdma: ss=2147483647 ber=2147483647 rscp=2147483647 ecno=2147483647 level=0,mTdscdma=CellSignalStrengthTdscdma: rssi=2147483647 ber=2147483647 rscp=2147483647 level=0,mLte=CellSignalStrengthLte: rssi=-51 rsrp=-84 rsrq=-7 rssnr=23 cqiTableIndex=2147483647 cqi=2147483647 ta=2147483647 level=4 parametersUseForLevel=0,mNr=CellSignalStrengthNr:{ csiRsrp = 2147483647 csiRsrq = 2147483647 csiCqiTableIndex = 2147483647 csiCqiReport = [] ssRsrp = -64 ssRsrq = -11 ssSinr = 30 level = 4 parametersUseForLevel = 0 },primary=CellSignalStrengthLte}
RSRP_SWEEP_TEST                                                       | FAIL |
List '${match}' has no item in index 0.
------------------------------------------------------------------------------
UE Detach                                                             | PASS |
------------------------------------------------------------------------------
Stop QXDM Automation                                                  | PASS |
------------------------------------------------------------------------------
Demo 1                                                                | FAIL |
5 tests, 4 passed, 1 failed
==============================================================================
Output:  /home/oranautomation/automation/SWEEP_TESTCASES/output.xml
