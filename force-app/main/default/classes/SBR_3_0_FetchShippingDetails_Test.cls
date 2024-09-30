@isTest
private class SBR_3_0_FetchShippingDetails_Test {

    @isTest
    static void testGetAcctShippingDetailsPos() {
        // Acct Test Data
        
        RecordType productRecordType = [SELECT Id FROM RecordType WHERE SObjectType = 'Account' AND DeveloperName = 'Credit' LIMIT 1];
        
        Account testAccount = new Account(
            Name = 'Test Account',
            RecordTypeId = productRecordType.Id,
            ShippingStreet = '123 Test St',
            ShippingCity = 'CLIFTON',
            ShippingCountry ='US',
            ShippingState = 'NJ',
            ShippingPostalCode = '12345',
            Company_Code__c ='01',
            Phone = '1234567890'
        );
        insert testAccount;

        //Test Method
        Map<String, Object> result = SBR_3_0_FetchShippingDetails.getAcctShippingDetails(testAccount.Id);

        // Assert
        System.assertEquals('123 Test St', result.get('addressLine1'), 'Address not found');
        System.assertEquals('CLIFTON', result.get('shipToCity'), 'Shipping City not found');
        //System.assertEquals('NJ', result.get('shipToState'), 'State not found');
        System.assertEquals('12345', result.get('shipToZip'), 'ZipCode not found');
    }
    @isTest
    static void testGetAcctShippingDetailsNeg() {
        //Test Method
        Map<String, Object> result = SBR_3_0_FetchShippingDetails.getAcctShippingDetails('12345');

        // Assert
        System.assertEquals('List has no rows for assignment to SObject', result.get('error'), 'Error Test');
    }

    @isTest
    static void testGetBranchShippingDetailsPos() {
        // Location Test Data
        Schema.Location testLocation = new Schema.Location(
            Name = 'Test Branch',
            City__c = 'Test City',
            State__c = 'NJ',
            Street_Address__c = '123 Test St',
            Zip_Code__c = '12345',
            Phone__c = '1234567890'
        );
        insert testLocation;

        //Test Method
        Map<String, Object> result = SBR_3_0_FetchShippingDetails.getBranchShippingDetails(testLocation.Id);

        // Assert 
        System.assertEquals('123 Test St', result.get('addressLine1'), 'Address not found');
        System.assertEquals('Test City', result.get('shipToCity'), 'Shipping city not found');
        System.assertEquals('NJ', result.get('shipToState'), 'State not found');
        System.assertEquals('12345', result.get('shipToZip'), 'zip not found');
        System.assertEquals('1234567890', result.get('phoneNumber'), 'Phone not found');
    }

    @isTest
    static void testGetBranchShippingDetailsNeg() {
        //Test Method
        Map<String, Object> result = SBR_3_0_FetchShippingDetails.getBranchShippingDetails('12345');

        // Assert 
        System.assertEquals('List has no rows for assignment to SObject', result.get('error'), 'Error Test');
    }

    @isTest
    static void testGetVendorContacts() {
        // Create test data
        Account testAccount = new Account(Name = 'Test Account');
        insert testAccount;

        Contact testContact = new Contact(
            AccountId = testAccount.Id,
            FirstName = 'Test',
            LastName = 'Contact',
            Phone = '9999234234',
            MailingStreet = '123 Test St',
            MailingCity = 'Columbus',
            MailingState = 'OH',
            MailingPostalCode = 'L4C1O7',
            MailingCountry = 'US'
            //MailingStateCode = 'OH'
        );
        insert testContact;

        //Test Method
        List<Contact> contacts = SBR_3_0_FetchShippingDetails.getVendorContacts(testAccount.Id);

        // Assert
        System.assertEquals(1, contacts.size(), 'Contact not found');
        System.assertEquals('Test Contact', contacts[0].Name, 'Contact not found');
                
    }
}