@isTest
public class PPA_TableForAnalyticsController_Test {
    
    @testSetup
    static void makeData(){        
        RecordType productRecordType = [SELECT Id,name,DeveloperName FROM RecordType where SObjectType='PPA_Price_List__c' AND DeveloperName = 'PPA_Renewal' LIMIT 1];
        
        User testUser = new User(LastName = 'User',
                                 FirstName = 'PPA',
                                 Email = 'PPAUser@test.com',
                                 Username = 'pPAUser@test.com',
                                 Alias = 'pPAUser',
                                 TimeZoneSidKey = 'GMT',
                                 LocaleSidKey = 'en_US',
                                 EmailEncodingKey = 'UTF-8',
                                 ProfileId = UserInfo.getProfileId(),
                                 LanguageLocaleKey = 'en_US'
                                 );
        insert testUser;
                
        List<PPA_Price_List__c> PriceLists = new List<PPA_Price_List__c>();
		PriceLists.add(new PPA_Price_List__c(Name='TEST',
                                             RecordTypeId = productRecordType.Id,
                                             PPA_Status__c='Draft',
                                             PPA_Current__c = true,
                                             OwnerId=testUser.Id,
                                             PPA_New_End_Date__c= Date.today(),
                                             PPA_Old_End_Date__c= Date.today()
                                             ));
        insert PriceLists;
    }

    @isTest
    public static void fetchPriceLisTestWithSelection() {
        PPA_Price_List__c testPriceList = [SELECT Id, PPA_Status__c, PPA_Health__c, PPA_Rep_Name__c, PPA_Dashboard_End_Date__c FROM PPA_Price_List__c LIMIT 1];
        String endDate = String.valueOf(testPriceList.PPA_Dashboard_End_Date__c.year()) + '-' + String.valueOf(testPriceList.PPA_Dashboard_End_Date__c.month()).leftPad(2, '0') + '-' + String.valueOf(testPriceList.PPA_Dashboard_End_Date__c.day()).leftPad(2, '0');
        
        Test.startTest();
        List<PPA_Price_List__c> result= PPA_TableForAnalyticsController.fetchPriceList('Draft', '', 'PPA User', endDate, 'Yes');
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Expected one record');
        System.assertEquals(testPriceList.Id, result[0].Id, 'The Fetched record should be same');
    } 
    
    @isTest
    public static void fetchPriceListTestWithoutSelection() {
        PPA_Price_List__c testPriceList = [SELECT Id, PPA_Status__c, PPA_Health__c, PPA_Rep_Name__c, PPA_Dashboard_End_Date__c FROM PPA_Price_List__c LIMIT 1];        
        Test.startTest();
        List<PPA_Price_List__c> result= PPA_TableForAnalyticsController.fetchPriceList('', '', '', '', '');
        Test.stopTest();
        
        System.assertEquals(1, result.size(), 'Expected one record');
        System.assertEquals(testPriceList.Id, result[0].Id, 'The Fetched record should be same');
    }
}