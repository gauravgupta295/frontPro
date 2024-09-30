/*********************************************************************************************************************
* Apex Class: SBR_3_0_InspectionTemplateOperationsTest
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - SERV-4125 - Test Class for SBR_3_0_InspectionTemplateOperations
---------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME                    DATE                DETAIL FEATURES
    1.0       Ritesh Mohapatra                  2023-Sep-25         Initial version
    2.0       Evan Kuminski                     2023-Oct-19         Added test for generateEqpMaintenanceStepOutboxesOnDeactivation()
*********************************************************************************************************************/
@isTest
public class SBR_3_0_InspectionTemplateOperationsTest 
{
	@isTest
    static void inspectionTempValidationTest()
    {
        Test.startTest();
        //Create Account
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '12345';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        relatedAccount.Phone = '9123456781';
        insert relatedAccount;
        
        Account relatedAccount2 = new Account();
        relatedAccount2.RM_Account_Number__c = '123456';
        relatedAccount2.Name = 'Account 2';
        relatedAccount2.BillingStreet = '123 Main Street';
        relatedAccount2.BillingCity = 'Toronto';
        relatedAccount2.BillingPostalCode = 'M9N7V6';
        relatedAccount2.BillingState = 'ON';
        relatedAccount2.BillingCountry = 'CA';
        relatedAccount2.Phone = '9123456720';
        insert relatedAccount2;
		
        //Create Location
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '1234';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.A360SPARK_ExternalId__c = '1234';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        insert branchLocation;
        
        //Create Product
        List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(1,FALSE);
        lProducts[0].Product_SKU__c = '657657';
        insert lProducts;
        
        //Create Assets
        Asset newAsset = new Asset();
        newAsset.AccountID = relatedAccount.id;
        newAsset.SM_PS_Current_Location__c = branchLocation.id;
        newAsset.SM_PS_Assigned_Location__c = branchLocation.id;
        newAsset.Status = 'Available';
        newAsset.Name = '112233';
        newAsset.Status = 'Available';
        newAsset.SM_PS_Company_Code__c = '12';
        newAsset.SM_PS_Cat_Class__c = 'TESTESTTEST';
        newAsset.SM_PS_Last_Transaction_Date__c = Date.today();
        newAsset.SM_PS_Category__c = '657';
        newAsset.SM_PS_Class__c = '657';
        insert newAsset;
        
        Asset newAsset2 = new Asset();
        newAsset2.AccountID = relatedAccount2.id;
        newAsset2.SM_PS_Current_Location__c = branchLocation.id;
        newAsset2.SM_PS_Assigned_Location__c = branchLocation.id;
        newAsset2.Status = 'Available';
        newAsset2.Name = 'Asset 2';
        newAsset2.Status = 'Available';
        newAsset2.SM_PS_Company_Code__c = '1';
        newAsset2.SM_PS_Cat_Class__c = 'HVSHBAS';
        newAsset2.SM_PS_Last_Transaction_Date__c = Date.today();
        newAsset2.SM_PS_Category__c = '756';
        newAsset2.SM_PS_Class__c = '756';
        insert newAsset2;

        Inspection_Template__c newInspRecord2 = new Inspection_Template__c();
        newInspRecord2.SM_PS_Product__c  = lProducts[0].id;
        newInspRecord2.SM_PS_Status__c = 'Draft';
        insert newInspRecord2;
        
        newInspRecord2.SM_PS_Asset__c = newAsset2.id;
        update newInspRecord2;

        Inspection_Template__c newInspRecord = new Inspection_Template__c();
        newInspRecord.SM_PS_Asset__c = newAsset.id;
        newInspRecord.SM_PS_Status__c = 'Draft';

        try
        {
        	insert newInspRecord;
            
        }
        catch(Exception ex)
        {
            Boolean expectedExceptionThrown =  (ex.getMessage().contains('This Asset\'s Cat Class Product is already assigned to this Work Plan Template')) ? true : false; 
        	System.AssertEquals(true, expectedExceptionThrown, ex.getMessage()); 
        }
        Test.stopTest();
    }

    @IsTest
    private static void generateOutboxesOnDeactivation() {
        SBR_3_0_EqpMaintenanceStepDAMock eqpMaintenanceStepDAMock = new SBR_3_0_EqpMaintenanceStepDAMock();
        Id mockId = SM_PS_Eqp_Maintenance_Step__c.SObjectType.getDescribe().keyPrefix + '000000000000';
        eqpMaintenanceStepDAMock.results = new List<SM_PS_Eqp_Maintenance_Step__c>{new SM_PS_Eqp_Maintenance_Step__c(Id=mockId, SM_PS_Company_Code__c='01')};
        SBR_3_0_InspectionTemplateOperations.eqpMaintenanceStepDA = eqpMaintenanceStepDAMock;
        Inspection_Template__c inspectionTemplate = new Inspection_Template__c(SM_PS_Status__c = SBR_3_0_InspectionTemplateOperations.ACTIVE_STATUS);
        insert inspectionTemplate;
        inspectionTemplate.SM_PS_Status__c = 'Deactivated';
        Test.startTest();
        {
            update inspectionTemplate;
        }
        Test.stopTest();

        Outbox__c result = [SELECT Id, Record_Id__c FROM Outbox__c];
        Assert.areEqual(mockId, result.Record_Id__c);
    }

    public class SBR_3_0_EqpMaintenanceStepDAMock implements SBR_3_0_EqpMaintenanceStepDAI {
        public List<SM_PS_Eqp_Maintenance_Step__c> results;
        public List<SM_PS_Eqp_Maintenance_Step__c> getAllFieldsByInspectionTemplateIds(Iterable<Id> inspectionTemplateIds) {
            return results;
        }
    }
}