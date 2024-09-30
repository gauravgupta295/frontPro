/*********************************************************************************************************************
* Apex Class: SBR_3_0_UpdateTechnicalAttributes_Test
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* Test Class for SBR_3_0_UpdateTechnicalAttributes
----------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME          DATE          DETAIL FEATURES
    1.0       Ritesh Mohapatra      2023-Dec-8      Initial version
**********************************************************************************************************************/
@isTest
public class SBR_3_0_UpdateTechnicalAttributes_Test 
{
    static testMethod void testPostCallout() 
    {	
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '12345';
        relatedAccount.Name = SBR_3_0_API_Web_Jobsite_DA.JOBSITEACCOUNTNAME;
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        relatedAccount.Phone  = '9874563217';
        relatedAccount.Company_Code__c = '01';
        insert relatedAccount;

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

        List<Contact> lstContacts = SBR_3_0_TestDataFactory.createContacts(1, relatedAccount.id, true);
        
        List<Product2> lstProds = SBR_3_0_TestDataFactory.createProducts(1, true);
        
        RecordType rt = [SELECT Id, DeveloperName, IsActive, Name, SobjectType FROM RecordType WHERE IsActive = true AND SobjectType = 'Asset' AND Name = 'Rental Asset' ];
        
        Asset newAsset = new Asset();
        newAsset.RecordTypeId = rt.Id;
        newAsset.AccountID = relatedAccount.id;
        newAsset.ContactID = lstContacts[0].id;
        newAsset.SM_PS_Current_Location__c = branchLocation.id;
        newAsset.SM_PS_Assigned_Location__c = branchLocation.id;
        newAsset.Status = 'Available';
        newAsset.Name = '112233';
        newAsset.SM_PS_Category__c = '657';
        newAsset.SM_PS_Class__c = '657';
        newAsset.Status = 'Available';
        newAsset.SM_PS_Company_Code__c = '01';
        newAsset.SM_PS_Cat_Class__c = 'TESTCATCLASS';
        newAsset.SM_PS_Last_Transaction_Date__c = Date.today();
        newAsset.SM_PS_Record_Status__c = 'Active';
        newAsset.SM_PS_Equipment_Number__c = '5964564';
        insert newAsset;
        
        SBR_3_0_UpdateTechnicalAttributes.Requests request = new SBR_3_0_UpdateTechnicalAttributes.Requests();
        List<SBR_3_0_UpdateTechnicalAttributes.Requests> requestBodyList = new List<SBR_3_0_UpdateTechnicalAttributes.Requests>();
       	
        request.calDays = '40';
        request.renDays = '50';
        request.meter = '60';
        request.assetRecordId = newAsset.id;
            
        requestBodyList.add(request);
        
        Test.startTest();
        Test.setMock(HttpCalloutMock.class, new SBR_3_0_UpdateTechnicalAttributes_Mock());  
        SBR_3_0_UpdateTechnicalAttributes.updateTechAttributes(requestBodyList);
        Test.stopTest();
    }
}