/*********************************************************************************************************************
* Apex Class: SBR_3_0_EquipOnHoldTriggerOp_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test Class to manage handler logic for Equipment on Hold 
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME      DATE            DETAIL FEATURES
    1.0         Ritesh Mohapatra    2022-11-23      Initial version (SAL-9546)
    2.0         Alex DeVries        2022-12-12      Updated SM_PS_Contract_Applied__c references to
                                                    reflect change from Numeric to Text field
*********************************************************************************************************************/
@isTest
public  with sharing class SBR_3_0_EquipOnHoldTriggerOp_Test 
{
	@TestSetup
    static void makeData()
    {
        Account accountRecord = new Account(Name = 'Global Designs Inc. [View Hierarchy]',
  											Phone = '123456789',                            
  											Company_Code__c = '01',
                                            BillingStreet='24 Willie Mays Plaza', 
                                            BillingCity= 'San Francisco',
                                            BillingState= 'CA',
                                            BillingCountry = 'US',
                                            BillingPostalCode='94017');
        insert accountRecord;
        
        Contract contractRecord = new Contract(StartDate = Date.parse('05/11/2022'),
                                     AccountId = accountRecord.id,
                                     Status = 'Draft');
        insert contractRecord;
        
        // Create Price Book
        Pricebook2 priceBook = new Pricebook2(
            Id = Test.getStandardPricebookId(),
            IsActive = true
        );
        update priceBook;
        
        Order orderRecord = new Order(Contract_Order_Number__c = '102939',   
                                      Type = 'SalesOrder',                         
                                      Status = 'Draft', 
                                      Name = 'Test Order',
                                      Start_Date__c = System.today().addMonths(1),
                                      EffectiveDate = System.today().addMonths(2),
                                      EndDate = System.today().addMonths(4),
                                      Earliest_Delivery_Date__c = System.today().addMonths(3),
                                      Pricebook2Id = priceBook.Id,
                                      RecordTypeId = Schema.SObjectType.Order.getRecordTypeInfosByName().get('Contract Order').getRecordTypeId(),
                                      ContractId = contractRecord.id,
                                      AccountId = accountRecord.id);
        insert orderRecord;
        
        Asset assetRecord = new Asset(SM_PS_Cat_Class__c = '0480200', 
                              SM_PS_Equipment_Number__c = '100016',
                              Name ='10266',
                              Status = 'ON RENT',
                              SM_PS_Equipment_Type__c = 'RENTAL',
                              AccountId = accountRecord.id                                  
                            );
                            insert assetRecord; 
        
        Equipment_on_Hold__c equipOnHold = new Equipment_on_Hold__c(SM_PS_Company_Code__c = '01',                                  
                                                                    SM_PS_Hold_Request_From_Date__c = Date.parse('11/11/2022'),  
                                                                    SM_PS_Contract_Applied__c = '102939',
                                                              		SM_PS_Asset_Id__c = assetRecord.Id,                                   
                                                                    SM_PS_Status__c = 'Active');
		insert equipOnHold;
    }
    
    @isTest static void updateContractOrderAppliedTest()
    {
        Equipment_on_Hold__c eQHold = [SELECT Id, SM_PS_Contract_Order_Applied__c,SM_PS_Company_Code__c, SM_PS_Contract_Applied__c
                                       FROM Equipment_on_Hold__c
                                       WHERE SM_PS_Company_Code__c = '01'];
        
        eQHold.SM_PS_Status__c = 'Filled';
        
        Update eQHold;
        Equipment_on_Hold__c eQHold2 = [SELECT Id, SM_PS_Contract_Order_Applied__c,SM_PS_Company_Code__c, SM_PS_Contract_Applied__c
                                       FROM Equipment_on_Hold__c
                                       WHERE SM_PS_Company_Code__c = '01'];
        Order od = [SELECT id from Order Where Contract_Order_Number__c = '102939' ];
        System.assertEquals(od.id, eQHold2.SM_PS_Contract_Order_Applied__c);
    }
}