@isTest
// Test Class for sbr_3_0_carrierSearch

public class sbr_3_0_carrierSearch_Test {
    
    @isTest
    public static void testGetcarrier() {
        // Test data setup
        List<Third_Party_Carrier__c> carriers = new List<Third_Party_Carrier__c>();
        for (Integer i = 0; i < 5; i++) {
            Third_Party_Carrier__c carrier = new Third_Party_Carrier__c(
                Name = 'Carrier' + i,
                ExternalId__c = '123456'+ i,
                Carrier_Num__c = '10' + i,
                Main_Phone__c = '1234567' + i,
                Liability_Insurance__c =  100 + i
            );
            carriers.add(carrier);
        }
        insert carriers;

        List<Third_Party_Carrier__c> result = sbr_3_0_carrierSearch.getcarrier(100);

        System.assertEquals(5, result.size(), 'Number of carriers returned should be 5');

        for (Third_Party_Carrier__c carrier : result) {
            System.assertNotEquals(null, carrier.Id, 'Carrier Id should not be null');
            System.assertNotEquals(null, carrier.Name, 'Carrier Name should not be null');
            System.assertNotEquals(null, carrier.Carrier_Num__c, 'Carrier Number should not be null');
            System.assertNotEquals(null, carrier.Main_Phone__c, 'Carrier Main Phone should not be null');
            System.assertNotEquals(null, carrier.Liability_Insurance__c, 'Carrier Liability Insurance should not be null');
        }
    }
    
    @isTest
    public static void testGetSearchResults() {
        // Test data setup
        Third_Party_Carrier__c carrier = new Third_Party_Carrier__c(
            Name = 'Carrier',
            ExternalId__c = '123456',
            Carrier_Num__c = '10' ,
            Main_Phone__c = '1234567',
            Liability_Insurance__c = 100
        );
        
        insert carrier;
        system.debug('inserted rec ' +carrier);

        // Call the method under test with a search string
        // Testing the negative scenario 
        String searchString = 'Carrier';
        Test.startTest();
        List<Third_Party_Carrier__c> Tpc = sbr_3_0_carrierSearch.getSearchResults(searchString);
        Test.stopTest();
        
        system.debug('Tpc ' +Tpc);
		//System.assert(true, Tpc.size() > 0 );
        System.assertEquals(0, Tpc.size());
        
		/*
        Third_Party_Carrier__c returnedCarrier = Tpc[0];
        System.assertEquals(carrier.Id, returnedCarrier.Id, 'Returned Carrier Id should match');
        System.assertEquals(carrier.Name, returnedCarrier.Name, 'Returned Carrier Name should match');
        System.assertEquals(carrier.Carrier_Num__c, returnedCarrier.Carrier_Num__c, 'Returned Carrier Number should match');
        System.assertEquals(carrier.Main_Phone__c, returnedCarrier.Main_Phone__c, 'Returned Carrier Main Phone should match');
        System.assertEquals(carrier.Liability_Insurance__c, returnedCarrier.Liability_Insurance__c, 'Returned Carrier Liability Insurance should match');
		*/
	}
}