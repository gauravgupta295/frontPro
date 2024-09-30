@istest
public class SBR_3_0_DuplicateResults_Test {
    @istest
    public static void testDuplicates()
    {
         Account acct = new Account();
        acct.RM_Account_Number__c = '4';
        acct.Company_Code__c = '01';
        acct.Name = 'Test Account';
        acct.Record_Type_Text__c = 'Credit';
        acct.E_mail_Address__c = '123@asdf.com';
        acct.Phone = '1234567890';
        acct.BillingStreet = '123 Main Street';
        acct.BillingCity = 'Toronto';
        acct.BillingPostalCode = 'M9N7V5';
        acct.BillingState = 'ON';
        acct.BillingCountry = 'CA';
        acct.Drivers_License__c = 'AKF';
        acct.Driver_s_License_State__c = 'AL';
        insert acct;
            Contact cont = new Contact();
        cont.FirstName = 'Test';
        cont.LastName = 'TEST';
        cont.AccountId = acct.Id;
        cont.MobilePhone = '5555555555';
        cont.Phone = '5555555555';
        cont.Email = 'test@test.com';
        cont.MailingStreet = '12 Main Street';
        cont.MailingCity = 'Toronto';
        cont.MailingPostalCode = 'M7N7B3';
        cont.MailingState = 'ON';
        cont.MailingCountry = 'CA';
        insert cont;
             Contact cont2 = new Contact();
        cont2.FirstName = 'Test';
        cont2.LastName = 'TEST';
        cont2.AccountId = acct.Id;
        cont2.MobilePhone = '5555555555';
        cont2.Phone = '5555555555';
        cont2.Email = 'test@test.com';
        cont2.MailingStreet = '12 Main Street';
        cont2.MailingCity = 'Toronto';
        cont2.MailingPostalCode = 'M7N7B3';
        cont2.MailingState = 'ON';
        cont2.MailingCountry = 'CA';
     //   insert cont2;
     Test.startTest();
        Database.saveResult result=database.insert( cont2,false);
      List<SObject> obj=  SBR_3_0_DuplicateResults.getDuplicatedRecords(result);
        Test.StopTest();
        System.assertEquals(obj.size(), 1);
        
        
    }
    

}