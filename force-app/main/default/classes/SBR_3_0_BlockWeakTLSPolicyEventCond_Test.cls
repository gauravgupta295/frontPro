@isTest
public class SBR_3_0_BlockWeakTLSPolicyEventCond_Test {

    @isTest
    public static void evaluateTest() {
		LoginEvent event = new LoginEvent();
        Boolean response;
		event.CipherSuite = 'ecdhe-rsa-AES128-SHA256';
        
        Test.startTest();
		response = SBR_3_0_BlockWeakTLSPolicyEventCond.evaluate(event);
        assert.isTrue(response, 'Should have been blocked');

       	event.CipherSuite = 'TEST';
		response = SBR_3_0_BlockWeakTLSPolicyEventCond.evaluate(event);
        assert.isFalse(response, 'Should not have been blocked');

        Test.stopTest();        
    }
}