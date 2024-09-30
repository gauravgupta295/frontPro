/*********************************************************************************************************************
* Apex Class: SBR_3_0_UploadPSCItems_Controller_Test
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* SERV-8180 - Test Class for SBR_3_0_UploadPSCItems_Controller
----------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME        DATE            MOD LOG
    1.0       Ritesh Mohapatra      2023-Dec-6     Initial version (SERV-8180)
	
**********************************************************************************************************************/
@isTest
public class SBR_3_0_UploadPSCItems_Controller_Test 
{
	@isTest
    static void uploadPSCItems()
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
        
        ProductServiceCampaign pscRecord1 = new ProductServiceCampaign(ProductServiceCampaignName = 'TEST 1 PRODUCT SERVICE CAMPAIGN');
        pscRecord1.SM_PS_Company_Code__c = '01';
        pscRecord1.SM_PS_Labor_Code__c = '1234';
        pscRecord1.SM_PS_Maintenance_Step_Y_N__c = 'N';
        pscRecord1.Status = 'Draft';
        pscRecord1.SM_PS_Est_Hrs_to_Complete__c = 4;
        pscRecord1.SM_PS_Search_Word__c = 'TEST';
        pscRecord1.SM_PS_Step_Number__c = '24000';
        pscRecord1.StartDate = Date.newInstance(2023, 11, 6);
        pscRecord1.Type = 'Mandatory Non-Safety';
        insert pscRecord1;
        
        Test.startTest();
        
        String[] fieldOptions = SBR_3_0_UploadPSCItems_Controller.getDeliveryMethodValues();
        String sampleCsv = SBR_3_0_UploadPSCItems_Controller.getExampleCsvContent();
        String fileName = 'exampleTemplateUpload (10).csv';
        String base64Data = 'Q09NUEFOWSBDT0RFLEVRVUlQTUVOVCBOVU1CRVIsQVNTRVQgSUQNCjEsNTk2NDU2NCwwMS01OTY0NTY0DQoyLDU3OTc0NjMsMDItNTc5NzQ2Mw0KMyw1Nzk3NDY0LDAzLTU3OTc0NjQ%3D';
        String base64DateEmpty = 'Q09NUEFOWSBDT0RFLEVRVUlQTUVOVCBOVU1CRVIsQVNTRVQgSUQ%3D';
        String delmethodSelected1 = 'WorkOrder';
        String delmethodSelected2 = 'AssetNotification';
        String delmethodSelected3 = 'Both - Work Order & Asset Notification';
        
        String finalStr = SBR_3_0_UploadPSCItems_Controller.preparePSCItems(fileName,base64Data,pscRecord1.id,delmethodSelected1);
        String finalStr2 = SBR_3_0_UploadPSCItems_Controller.preparePSCItems(fileName,base64Data,pscRecord1.id,delmethodSelected2);
        String finalStr3 = SBR_3_0_UploadPSCItems_Controller.preparePSCItems(fileName,base64Data,pscRecord1.id,delmethodSelected3);
        String finalStr4 = SBR_3_0_UploadPSCItems_Controller.preparePSCItems(fileName,base64DateEmpty,pscRecord1.id,delmethodSelected3);

        System.AssertEquals('SUCCESS',finalStr);
        System.AssertEquals('The CSV file is empty or only contains headers',finalStr4);
        
        Test.stopTest();
    }
}