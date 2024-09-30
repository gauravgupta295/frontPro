@IsTest(SeeAllData=false) 
public class SBR_3_0_CustomerSpendOperations_Test {

    @TestSetup
    static void makeData(){
        Analysis_Region__c AR = new Analysis_Region__c();
        AR.name = 'CLIMATE CONTROL DIVISION';
        AR.Status__c = 'Active';
        AR.Unique_Name__c = '007-011';
        AR.Company_Code__c = '007';
        AR.Analysis_Region_Key__c = '011';
        insert AR;
        
    }
    @isTest
    public static void test1(){
        Test.startTest();
        List<Customer_spend__c> spendList = new List<Customer_spend__c>();
        List<Account> accountList =SBR_3_0_TestDataFactory.createAccounts(3, false, SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT);
        for(Account a: accountList){
            a.BillingStreet = '';
            a.BillingCity = '';
            a.BillingState = '';
            a.BillingPostalCode = '';
            a.BillingCountry = '';
            a.ShippingStreet = '';
            a.ShippingCity = '';
            a.ShippingState = '';
            a.ShippingPostalCode = '';
            a.ShippingCountry = '';
        }
        accountList[1].recordtypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get(SBR_3_0_Constants.ACCOUNT_REC_TYPE_CREDIT).getRecordTypeId();
        accountList[0].recordtypeId= Schema.SObjectType.Account.getRecordTypeInfosByName().get(SBR_3_0_Constants.ACCOUNT_REC_TYPE_OFFICE).getRecordTypeId();
        
        insert accountList; 
        accountList[0].ParentId = accountList[1].Id;
        update accountList[0];

        Customer_Spend__c spend = new Customer_Spend__c();
        spend.Analysis_Region__c = [Select id from Analysis_Region__c limit 1].id;
        spend.Account__c = accountList[1].Id;
        spendList.add(spend);
        Customer_Spend__c spend1 = new Customer_Spend__c();
        spend1.Analysis_Region__c = [Select id from Analysis_Region__c limit 1].id;
        spend1.Account__c = accountList[0].Id;
        spendList.add(spend1);
        insert spendList;
        update spend1;
        Test.stopTest();
    }
}