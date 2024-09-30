@isTest
public class SBR_3_0_VDOS_UpdateWorkOrderWrapper_Test {

    @isTest
    static void testParse(){
        string jsonString = '{"data":{"vdosId":"12345","sfWorkOrderId":"243697","rmWorkOrderId":"243697","resultSetMsg":null,"companyId":"02"}}';   
        SBR_3_0_VDOS_UpdateWorkOrderWrapper.parse(jsonString);
    }
        
}