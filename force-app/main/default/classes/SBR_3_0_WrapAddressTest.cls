/*********************************************************************************************************************
* Apex Class: SBR_3_0_WrapAddressTest
---------------------------------------------------------------------------------------------------------------------------------------
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Abhi Chauhan           				2023-April-05        Initial version
*********************************************************************************************************************/

@isTest
private class SBR_3_0_WrapAddressTest {

    @isTest
    static void testSBR_3_0_WrapAddress() {
        // Test data
        String testStreet1 = '123 Main St';
        String testStreet2 = 'Apt 4B';
        String testCity = 'San Francisco';
        String testState = 'CA';
        String testZip = '12345';
        String testCountry = 'USA';
        Decimal testLatitude = 37.7749;
        Decimal testLongitude = -122.4194;

        // Create a new instance of SBR_3_0_WrapAddress
        SBR_3_0_WrapAddress wrapAddress = new SBR_3_0_WrapAddress();
        wrapAddress.street1 = testStreet1;
        wrapAddress.street2 = testStreet2;
        wrapAddress.city = testCity;
        wrapAddress.state = testState;
        wrapAddress.zip = testZip;
        wrapAddress.country = testCountry;
        wrapAddress.latitude = testLatitude;
        wrapAddress.longitude = testLongitude;

        // Test getters
        System.assertEquals(testStreet1, wrapAddress.street1);
        System.assertEquals(testStreet2, wrapAddress.street2);
        System.assertEquals(testCity, wrapAddress.city);
        System.assertEquals(testState, wrapAddress.state);
        System.assertEquals(testZip, wrapAddress.zip);
        System.assertEquals(testCountry, wrapAddress.country);
        System.assertEquals(testLatitude, wrapAddress.latitude);
        System.assertEquals(testLongitude, wrapAddress.longitude);

        // Test setters
        String newStreet1 = '456 Oak St';
        wrapAddress.street1 = newStreet1;
        System.assertEquals(newStreet1, wrapAddress.street1);

       
    }
}