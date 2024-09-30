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
public class SBR_3_0_WrapWorkOrder_Test {
	@isTest
    static void testSBR_3_0_WrapWorkOrder() {
        String JSON = '{"timestamp":"system.today","user":"testUser","systemName":"Salesforce","rentalmanUser":"rentalManTestUser","salesforceWorkOrderNumber":"3","salesforceWorkOrderLineNumber":"4","WorkOrder":[{"companyCode":"cmp001","jobNumber":"J-001","accountNumber":"A-0001","locationCode":"Loc-001","equipmentNumber":"EQ-001","expenseToLocation":"ETL-001","salesRep":"SP-001","mechanic":"testuser","estimatedCompletionDate":"1/1/2025","majorRepair":"yes","workOrderDescription":"testDEscription","descriptionOfProblem":"test","laborCode":"LSR","currencyCode":"USD","expenseCode":"ex-001","jobLocation":"J-001","pONumber":"PO-001","dlNumber":"DL-001","serialNumber":"0000122","phoneNumber":"2342182121","openedDate":"1/1/2023","authorizedBy":"testUser","servicecall":"test-001","repairTicketNumber":11.00,"creationTimestamp":"14/6/2024","currentMiHr":10.00,"currentMiHr2":10.00,"marketSegment":"segment"}]}';
        Test.startTest();
            SBR_3_0_WrapWorkOrder responseWrap = SBR_3_0_WrapWorkOrder.parse(JSON);
        Test.stopTest();
    }
}