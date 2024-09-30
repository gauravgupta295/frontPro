@isTest

public class SBR_3_0_SyncAccountJsonParserTest {

public static testMethod void testParse() {
		String json=		'{'+
		'    "data": {'+
		'        "crossReferenceNumber": "00000000000000820242",'+
		'        "rmAccountNumber": "12146"'+
		'    }'+
		'}';
		SBR_3_0_SyncAccountJsonParser obj = SBR_3_0_SyncAccountJsonParser.parse(json);
		System.assert(obj != null);
	}
}