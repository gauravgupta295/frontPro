/*********************************************************************************************************************
* Apex Class: SBR_3_0_GetValueFromMapInFlow_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_GetValueFromMapInFlow class
* - SAL-852
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Avinash Rao           2022-02-24            Initial version    
*********************************************************************************************************************/
@isTest
private class SBR_3_0_GetValueFromMapInFlow_Test {

    @isTest static void testgetValue(){
        List<SBR_3_0_GetValueFromMapInFlow.GetValueInputs> inputs = new List<SBR_3_0_GetValueFromMapInFlow.GetValueInputs>();
        SBR_3_0_GetValueFromMapInFlow.GetValueInputs input = new SBR_3_0_GetValueFromMapInFlow.GetValueInputs();
        input.key = 'Prospect1';
        List<SBR_3_0_GetRecordTypesFlowMapClass> flowMapList = new List<SBR_3_0_GetRecordTypesFlowMapClass>();
        for(integer i = 0; i< 3; i++){
            SBR_3_0_GetRecordTypesFlowMapClass j = new SBR_3_0_GetRecordTypesFlowMapClass();
            j.key = 'Prospect'+i;
            j.value = 'XYZZY10023'+i+'41AU';
            flowMapList.add(j);
        }
        input.flowMap = flowMapList;
        inputs.add(input);
        List<SBR_3_0_GetValueFromMapInFlow.GetValueOutputs> result = new List<SBR_3_0_GetValueFromMapInFlow.GetValueOutputs>();
        //test getValue when a match is found
		result = SBR_3_0_GetValueFromMapInFlow.getValue(inputs);
        System.assertEquals('XYZZY10023141AU', result[0].outputValue, 'getValue method returns the value in a map using provided key');
        //test getValue when a match is not found
        inputs[0].key = 'Prospect 4';
        result = SBR_3_0_GetValueFromMapInFlow.getValue(inputs);
        System.assertEquals(0, result.size(), 'getValue method returns an empty list since there was no match');
    }
    
}