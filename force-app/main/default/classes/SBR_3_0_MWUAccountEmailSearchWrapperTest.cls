/**
 * @description       : 
 * @author            : Hamza ASKOUR
 * @group             : 
 * @last modified on  : 01-02-2024
 * @last modified by  : Hamza ASKOUR
**/
@isTest
public with sharing class SBR_3_0_MWUAccountEmailSearchWrapperTest {
    
    @isTest
    static void testParseMethod() {
        // Test JSON data to simulate input
        String jsonString = '{"data": {"users": [{"email": "test@example.com"}]}, "error": {"message": "Error Message", "errorKey": "Key", "errorCode": "123"}}';

        // Call the parse method
        SBR_3_0_MWUAccountEmailSearchWrapper result = SBR_3_0_MWUAccountEmailSearchWrapper.parse(jsonString);

        // Verify that the parsing is successful
        System.assertNotEquals(null, result);
        System.assertNotEquals(null, result.data);
        System.assertNotEquals(null, result.data.users);
        System.assertEquals(1, result.data.users.size());
        System.assertEquals('test@example.com', result.data.users[0].email);

        System.assertNotEquals(null, result.error);
        System.assertEquals('Error Message', result.error.message);
        System.assertEquals('Key', result.error.errorKey);
        System.assertEquals('123', result.error.errorCode);
    }
}