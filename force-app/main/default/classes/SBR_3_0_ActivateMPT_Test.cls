/*********************************************************************************************************************
* Apex Class: SBR_3_0_ActivateMPT_Test
----------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* Test Class for SBR_3_0_ActivateMaintenancePlanTemplate & SBR_3_0_AssetUpdateOnMPTActivationBatch
----------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME          DATE          DETAIL FEATURES
    1.0         Ritesh Mohapatra      2023-Dec-18     Initial version  
**********************************************************************************************************************/
@isTest
public class SBR_3_0_ActivateMPT_Test 
{
	@isTest
    static void activateMPT()
    {	
        //Create Products
        List<Product2> lProducts = SBR_3_0_TestDataFactory.createProducts(3,FALSE);
        lProducts[0].Product_SKU__c = '010425';
        lProducts[1].Product_SKU__c = '010426';
        lProducts[2].Product_SKU__c = '010427';
        insert lProducts;
       
        //Create Account
        Account relatedAccount = new Account();
        relatedAccount.RM_Account_Number__c = '12345';
        relatedAccount.Name = 'TEST ACCOUNT';
        relatedAccount.BillingStreet = '123 Main Street';
        relatedAccount.BillingCity = 'Toronto';
        relatedAccount.BillingPostalCode = 'M9N7V5';
        relatedAccount.BillingState = 'ON';
        relatedAccount.BillingCountry = 'CA';
        relatedAccount.Phone = '9123456781';
        insert relatedAccount;
        
        List<Contact> lstContacts = SBR_3_0_TestDataFactory.createContacts(3, relatedAccount.id, true);
        Id rentalAssetRTId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Rental_Asset').getRecordTypeId();
        Id cmpOwnAssetRTId = Schema.SObjectType.Asset.getRecordTypeInfosByDeveloperName().get('Company_Owned_Asset').getRecordTypeId();

        Asset newAsset1 = new Asset();
        newAsset1.RecordTypeId = rentalAssetRTId;
        newAsset1.AccountID = relatedAccount.id;
        newAsset1.ContactID = lstContacts[0].id;
        newAsset1.Product2Id = lProducts[0].id;
        newAsset1.Status = 'AVAILABLE';
        newAsset1.Name = 'ASSET NAME 1';
        newAsset1.SM_PS_Company_Code__c = '01';
        newAsset1.SM_PS_Cat_Class__c = '112233AHIFODIFHDFHDIOFIFHDSSSSC';
        newAsset1.SM_PS_Last_Transaction_Date__c = Date.today();
        newAsset1.SM_PS_Commissioning_Complete__c = TRUE;
        newAsset1.SM_PS_Category__c = '01';
        newAsset1.SM_PS_Class__c = '0425';
        
        Asset newAsset2 = new Asset();
        newAsset2.RecordTypeId = cmpOwnAssetRTId;
        newAsset2.AccountID = relatedAccount.id;
        newAsset2.ContactID = lstContacts[1].id;
        newAsset2.Product2Id = lProducts[1].id;
        newAsset2.Status = 'AVAILABLE';
        newAsset2.Name = 'ASSET NAME 2';
        newAsset2.SM_PS_Company_Code__c = '02';
        newAsset2.SM_PS_Cat_Class__c = '112233AHIFODIFHDFHDIOFIFHDSSSSCCI';
        newAsset2.SM_PS_Last_Transaction_Date__c = Date.today();
        newAsset2.SM_PS_Commissioning_Complete__c = TRUE;
        newAsset2.SM_PS_Category__c = '01';
        newAsset2.SM_PS_Class__c = '0426';
        
        Asset newAsset3 = new Asset();
        newAsset3.RecordTypeId = cmpOwnAssetRTId;
        newAsset3.AccountID = relatedAccount.id;
        newAsset3.ContactID = lstContacts[2].id;
        newAsset3.Product2Id = lProducts[2].id;
        newAsset3.Status = 'AVAILABLE';
        newAsset3.Name = 'ASSET NAME 3';
        newAsset3.SM_PS_Company_Code__c = '03';
        newAsset3.SM_PS_Cat_Class__c = '112233AHIFODIFHDFHDIOFIFHDSSSSCCIIFODSAS';
        newAsset3.SM_PS_Last_Transaction_Date__c = Date.today();
        newAsset3.SM_PS_Commissioning_Complete__c = TRUE;
        newAsset3.SM_PS_Category__c = '01';
        newAsset3.SM_PS_Class__c = '0427'; 

        List<Asset> assetInsList = new List <Asset>();
        assetInsList.add(newAsset1);
        assetInsList.add(newAsset2);
        assetInsList.add(newAsset3);
        insert assetInsList;
        
        //Maintenance Plan Template  Record Creation
        SVMXA360__MaintenancePlanTemplate__c mptRecord = new SVMXA360__MaintenancePlanTemplate__c();
        mptRecord.Name = 'TEST MAINTENANCE PLAN TEMPLATE';
        mptRecord.SVMXA360__GenerationTimeframe__c = 14;
        mptRecord.SVMXA360__GenerationTimeframeType__c = 'Days';
        mptRecord.SVMXA360__MaintenancePlanDuration__c = 10;
        mptRecord.SVMXA360__MaintenancePlanUnitOfTime__c = 'Days';
        mptRecord.SM_PS_Company_Code__c = '01';
        mptRecord.SVMXA360__IsActive__c = FALSE;
        insert mptRecord;
        
        System.debug('**mptRecord:'+mptRecord);
        
        //Create Applicable Products
        List<SVMXA360__ApplicableProduct__c> appProdList = new List<SVMXA360__ApplicableProduct__c>();
        
        SVMXA360__ApplicableProduct__c matchingApplicableProduct = new SVMXA360__ApplicableProduct__c(
                SVMXA360__ProductId__c = lProducts[0].id,
                SVMXA360__MaintenancePlanTemplateId__c = mptRecord.id
        );
        
        SVMXA360__ApplicableProduct__c matchingApplicableProduct2 = new SVMXA360__ApplicableProduct__c(
                SVMXA360__ProductId__c = lProducts[1].id,
                SVMXA360__MaintenancePlanTemplateId__c = mptRecord.id
        );
        
        SVMXA360__ApplicableProduct__c matchingApplicableProduct3 = new SVMXA360__ApplicableProduct__c(
                SVMXA360__ProductId__c = lProducts[2].id,
                SVMXA360__MaintenancePlanTemplateId__c = mptRecord.id
        );
        
        appProdList.add(matchingApplicableProduct);
        appProdList.add(matchingApplicableProduct2);
        appProdList.add(matchingApplicableProduct3);
        
        insert appProdList;
         
        
        Test.startTest();
        mptRecord.SVMXA360__IsActive__c = TRUE;
        update mptRecord;
        
        Test.stopTest();
    }
}