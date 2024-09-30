@isTest
public class SBR_3_0_CartDA_Test {
    @isTest
    static void testGetCart(){
        
        //Account Creation:
        List<Account> acc = SBR_3_0_TestDataFactory.createAccounts(1,true);
        //Branch Creation
        Schema.Location branchLocation = new Schema.Location();
        branchLocation.Branch_Location_Number__c = '1234';
        branchLocation.Name = 'Test Branch Location';
        branchLocation.Street_Address__c = '12 Main Street';
        branchLocation.City__c = 'Toronto';
        branchLocation.Zip_Code__c = 'M7N7B3';
        branchLocation.State__c = 'ON';
        branchLocation.Country__c = 'CA';
        branchLocation.Job_Number__c='332112';
        branchLocation.RecordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
        branchLocation.Company_Code__c = '01';
        insert branchLocation;
       
        //Contact Creation
        List<Contact> cons = SBR_3_0_TestDataFactory.createContacts(1,acc[0].Id,true);
        
        Cart__c c = new Cart__c();
        c.Account__c = acc[0].Id;
        c.Contact__c = cons[0].Id;
        c.Branch__c = branchLocation.Id;
        c.Rental_Start_Date__c = System.Now().addDays(1);
        c.Rental_End_Date__c = System.Now().addDays(2);
        c.Rental_Period__c = '7 Days';
        insert c;
        
        Test.startTest();
        Cart__c cart = SBR_3_0_CartDA.getCart(c.Id);
        Test.stopTest();
        
        System.AssertNotEquals(null,cart);
    }
    
 @isTest
    static void testGetCartNull(){
        Cart__c nullCart = new Cart__c();
        Test.startTest();
        Cart__c cart = SBR_3_0_CartDA.getCart(nullCart.Id);
        Test.stopTest();
        
        System.AssertEquals(null,cart);
        
    }
}