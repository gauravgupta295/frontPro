@isTest
public with sharing class PPA_PendingApprovalsLWCController_Test {
    
    @TestSetup
    static void makeData(){        
        List<PPA_Price_List__c> PriceLists = new List<PPA_Price_List__c>();
        String RecordTypeId;
        
        RecordTypeId = [SELECT Id FROM RecordType WHERE SObjectType = 'PPA_Price_List__c' AND DeveloperName='PPA_Extension'].Id;
        
        PriceLists.add(new PPA_Price_List__c(Name='TEST',
                                            PPA_CompanyId__c='01',
                                            RecordTypeId=RecordTypeId,
                                            PPA_Status__c='Pending Approval',
                                            OwnerId=UserInfo.getUserId(),
											PPA_Next_Approver__c=UserInfo.getUserId()
                    						)
					  );

        insert PriceLists;                        
    }
    
    @isTest
    public static void getPendingApprovalTest() {
        List<PPA_Price_List__c> PriceLists = new List<PPA_Price_List__c>();

        Test.startTest();
        PriceLists = PPA_PendingApprovalsLWCController.getPendingApproval();
        Test.stopTest();    

        Assert.areEqual(1, priceLists.size(), '1 Pending Approval should have been returned');
    }
}