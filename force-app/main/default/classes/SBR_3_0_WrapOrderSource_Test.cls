/*********************************************************************************************************************
* Apex Class: SBR_3_0_WrapOrderSource_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_WrapOrderSource //Added for FRONT-30844
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2024-06-14          Initial version    
**********************************************************************************************************************************************/
@isTest
public class SBR_3_0_WrapOrderSource_Test {
	@isTest
    static void testWrapOrderSource() {
        String JSON = '{"companyId":"test","cartId":"test2","cartTotal":0.00,"cartType":"test","sellingChannel":"3","jobsite":{"latitude":50.02,"longitude":20,"address":{"line1":"test1","line2":"test2","city":"us","state":"us","country":"Canada","zip":"test1"},"timezoneId":"123"},"pc":{"id":"123"},"products":[{"requestedDeliveryDate":"1/1/2024","lineId":"123","uom":"test","quantity":1,"productId":"123","productType":"abc","catId":"123","classId":"123"}],"salesItems":[{"itemNumber":"0001","stockClass":"test001","quantity":1,"unitPrice":2000.50}],"fulfillmentService":"fs001","fulfillmentType":"ft001","sourceSystem":"ws","considerCrowFlyingDistance":true,"customSourcingAudit":true}';
        Test.startTest();
            SBR_3_0_WrapOrderSource responseWrap = SBR_3_0_WrapOrderSource.parse(JSON);
        Test.stopTest();
    }
}