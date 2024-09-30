@isTest
public with sharing class SBR_3_0_API_ConsumablesRequest_Test {

    @isTest 
    static void testParse() {
        
        Test.startTest();
        String json = '{"pc":"0720","accountNumber":"4","jobsiteNumber":"CO MEDIMMUNE BOULDER","products":[{"catId":"020","classId":"0615"}]}';
        SBR_3_0_API_ConsumablesRequest wrappedRequest = SBR_3_0_API_ConsumablesRequest.parse(json);
        Test.stopTest();     
        System.assertEquals('0720', wrappedRequest.pc, 'PC does not match');
        System.assertEquals('020', wrappedRequest.products[0].catId, 'catId does not match');
    }
}