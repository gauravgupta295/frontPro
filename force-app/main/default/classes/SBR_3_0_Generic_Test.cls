/*********************************************************************************************************************
* Apex Class: SBR_3_0_Generic_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - @description - Test Class for SBR_3_0_Generic
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
    1.0         Sohail Azam                       	2024-01-17            Initial version    
*********************************************************************************************************************/

@isTest
public class SBR_3_0_Generic_Test {

    /**
     * @description - Test for generateRandomString method
    */
    @isTest
    static void testGenerateRandomString() {
        Integer expectedLength = 10;
        String randomString = SBR_3_0_Generic.generateRandomString(expectedLength);

        // Check if the generated string has the expected length
        Assert.areEqual(expectedLength, randomString.length(), 'Length of both the generated string and expected string is same');

        // Check if the generated string contains only valid characters
        for (Integer i = 0; i < randomString.length(); i++) {
            String currentChar = randomString.substring(i, i + 1);
            Assert.isTrue((currentChar >= 'a' && currentChar <= 'z') || (currentChar >= 'A' && currentChar <= 'Z') || (currentChar >= '0' && currentChar <= '9'), 'Generated String contains valid characters');
        }
    }

    /**
     * @description -Test for getDateTimeOfUser method
    */
    @isTest
    static void testGetDateTimeOfUser() {
        Test.startTest();

        // Call the method
        DateTime userDateTime = SBR_3_0_Generic.getDateTimeOfUser();

        Test.stopTest();

        // Get the current date and time for comparison
        Datetime currentDatetime = Datetime.now();
        Date nextDate = Date.newInstance(
            currentDatetime.year(),
            currentDatetime.month(),
            currentDatetime.day() + 1
        );

        Time setTimeAs8AM = Time.newInstance(8, 0, 0, 0);
        DateTime expectedDateTime = DateTime.newInstance(nextDate, setTimeAs8AM);

        // Check if the generated DateTime is as expected
        Assert.areEqual(expectedDateTime, userDateTime, 'DateTime is the next day at 8:00 AM');
    }
}