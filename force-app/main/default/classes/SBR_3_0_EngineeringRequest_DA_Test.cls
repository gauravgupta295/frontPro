@isTest
public class SBR_3_0_EngineeringRequest_DA_Test {

    @isTest
    static void getMostRecentRequestTest()
    {
        SBR_3_0_EngineeringRequest_DAInterface interfaceRequest = new SBR_3_0_EngineeringRequest_DA();
        Engineering_Request__c request = SBR_3_0_EngineeringRequest_DA.getMostRecentRequest();
        system.assert(request!=null);
    }
}