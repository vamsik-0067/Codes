RSRP sweep with DL UDP data
E2E_IOT_TID_004
Test Description
Purpose of this test case is to verify RSRP sweep with DL UDP data.
Test Setup
Pre-Conditions
gNB-CU-CP
gNB-CU-UP
gNB-DU
RU
Variable Attenuators
UE
Configure the ORU in 4x4 mode.
Bring up the CU and DU pods.
gNB should be operational state.
Ensure that there are no outstanding alarms.
Procedure
Expected Results
Capture UE logs.
Attach UE + DL UDP data.
Perform RSRP sweep with DL UDP data.
UE registration should be successful.
UE should achieve the peak throughput in DL.
DL UDP RSRP sweep results should be as per expectation at all RSRP points.
UE should remain connected through the test and no data Stall/RLF should be seen.
On restoring the RSRP to good, UE should attain the peak data rate as expected.
Test Result Summary (Pass/Fail)
