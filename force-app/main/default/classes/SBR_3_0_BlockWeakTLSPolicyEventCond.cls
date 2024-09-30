global with sharing class SBR_3_0_BlockWeakTLSPolicyEventCond implements TxnSecurity.EventCondition {

    public static Boolean evaluate(SObject event) {
        Set<String> listOfCiphers = new Set<String>();
        
        for(SBR_3_0_BlockWeakCipherSuite__mdt item : [SELECT MasterLabel FROM SBR_3_0_BlockWeakCipherSuite__mdt]) {
            listOfCiphers.add(item.MasterLabel.toUpperCase());
        }

        LoginEvent le = (LoginEvent) event;
		
        if(listOfCiphers.contains(le.CipherSuite.toUpperCase())) {
			return true;            
        }
        else {
        	return false;
        }
	}
}