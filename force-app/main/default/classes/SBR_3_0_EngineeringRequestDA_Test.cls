/*********************************************************************************************************************
* Apex Class: SBR_3_0_EngineeringRequestDA_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to test SBR_3_0_EngineeringRequestDA
* - 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Saathvik Tulasi      2023-01-11             Initial version    
*********************************************************************************************************************/
@isTest(seeAllData=false) 
public class SBR_3_0_EngineeringRequestDA_Test {
	/************************************************************* Cover getEngineeringRequestDetails Starts*************************************************************/
    public Static testMethod void getEngineeringRequestDetails(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        List<Engineering_Request__c> lER = SBR_3_0_TestDataFactory.createEngineeringRequest(2,TRUE);
        System.runAs(oUsers){
            Test.startTest();
            List<Engineering_Request__c> lERRes = SBR_3_0_EngineeringRequestDA.getEngineeringRequestDetails(lER[0].id);
            Test.stopTest();
        }
    }
    /************************************************************* Cover getEngineeringRequestDetails Ends*************************************************************/
    /************************************************************* Cover getSourceEngineeringRequest Starts*************************************************************/
    public Static testMethod void getSourceEngineeringRequest(){
		Profile oProfile = [SELECT Id FROM Profile WHERE Name='System Administrator'];
        User oUsers = SBR_3_0_TestDataFactory.createUser(TRUE,oProfile);
        List<Engineering_Request__c> lER = SBR_3_0_TestDataFactory.createEngineeringRequest(1,TRUE);
        List<Engineering_Request__c> lER1 = SBR_3_0_TestDataFactory.createEngineeringRequest(1,FALSE);
        lER1[0].Source_Engineering_Request__c = lER[0].id;
        INSERT lER1;
        System.runAs(oUsers){
            Test.startTest();
            List<Engineering_Request__c> lERRes = SBR_3_0_EngineeringRequestDA.getSourceEngineeringRequest(lER[0].id);
            Test.stopTest();
        }
    }
    /************************************************************* Cover getSourceEngineeringRequest Ends*************************************************************/
}