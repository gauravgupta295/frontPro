@isTest
public with sharing class SBR_3_0_GenerateFeedbackJson_Test {
    
    @TestSetup
    static void createData(){
        List<Account> accs = SBR_3_0_TestDataFactory.createAccounts(1, false, 'Credit');
        accs[0].Name = 'Hamza, A';
        accs[0].Driver_s_License_State__c = 'SC';
        accs[0].BillingState = 'SC';
        accs[0].BillingStreet = '1799 Innovation Point';
        accs[0].BillingCity = 'fortmill';
        accs[0].BillingCountry = 'US';
        accs[0].BillingPostalCode = '29715';
        accs[0].Drivers_License__c = '1233';
        accs[0].ShippingState = 'SC';
        accs[0].ShippingStreet = '1799 Innovation Point';
        accs[0].ShippingCity = 'fortmill';
        accs[0].ShippingCountryCode = 'US';
        accs[0].ShippingPostalCode = '29715';
        insert accs;

        List<Product_Recommendation_Feedback__c> recommendations = new List<Product_Recommendation_Feedback__c>();
        for(Integer i = 0; i < 2; i++) {
            Product_Recommendation_Feedback__c prf = new Product_Recommendation_Feedback__c(
                    Name = 'Rec'+i,
                    Cat_Class_Key__c = '120340'+i,
                    Feedback_Type__c = 'good',
                    Salesforce_Feedback_ID__c = 'SF Feedback'+i,
                    Rep_ID__c = String.valueOf(UserInfo.getUserId()),
                    Account_number__c = 'Acc-0001',
                    Company_Code__c = 01,
                    Account__c = accs[0].Id,
                    Additional_comments__c = 'Very Good',
                    Model_Version__c = 'Version '+i
            );
            recommendations.add(prf);
        }
        insert recommendations ;
    }


    @isTest
    public static void processRecordsTest(){
        test.startTest();
                    List<Product_Recommendation_Feedback__c> feedbacks = [SELECT Id,Name,Cat_Class_Key__c,Feedback_Type__c,Rep_ID__c,Account_number__c,Company_Code__c,Account__c,Salesforce_Feedback_ID__c,Additional_comments__c,Model_Version__c FROM Product_Recommendation_Feedback__c];
            String jsonResult = SBR_3_0_GenerateFeedbackJson.processRecords(feedbacks);
            System.assertNotEquals(jsonResult, null);
        test.StopTest();
    }

}