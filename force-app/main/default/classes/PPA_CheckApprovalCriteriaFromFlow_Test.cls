@isTest
public class PPA_CheckApprovalCriteriaFromFlow_Test {

    @TestSetup
    static void testSetup(){
        List<PPA_Price_List__c> priceLists = new List<PPA_Price_List__c>();
        priceLists.add(new PPA_Price_List__c(Name='TEST', PPA_Customer_TTM__c=500000));
        insert priceLists;
    }

    @isTest
    public static void checkApprovalCriteriaTestTrue() {
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        List<PPA_CheckApprovalCriteriaFromFlow.Outputs> outputs = new List<PPA_CheckApprovalCriteriaFromFlow.Outputs>();
        List<PPA_CheckApprovalCriteriaFromFlow.Inputs> inputs = new List<PPA_CheckApprovalCriteriaFromFlow.Inputs>();
        PPA_CheckApprovalCriteriaFromFlow.Inputs input = new PPA_CheckApprovalCriteriaFromFlow.Inputs();

        input.priceListId = priceList.Id;
        input.whereClause = 'PPA_Customer_TTM__c >= 500000';
        inputs.add(input);

        Test.startTest();
        outputs = PPA_CheckApprovalCriteriaFromFlow.checkApprovalCriteria(inputs);
        Test.stopTest();

        Assert.isTrue(outputs[0].criteriaPassed);
    }

    @isTest
    public static void checkApprovalCriteriaTestFalse() {
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        List<PPA_CheckApprovalCriteriaFromFlow.Outputs> outputs = new List<PPA_CheckApprovalCriteriaFromFlow.Outputs>();
        List<PPA_CheckApprovalCriteriaFromFlow.Inputs> inputs = new List<PPA_CheckApprovalCriteriaFromFlow.Inputs>();
        PPA_CheckApprovalCriteriaFromFlow.Inputs input = new PPA_CheckApprovalCriteriaFromFlow.Inputs();

        input.priceListId = priceList.Id;
        input.whereClause = 'PPA_Customer_TTM__c < 500000';
        inputs.add(input);

        Test.startTest();
        outputs = PPA_CheckApprovalCriteriaFromFlow.checkApprovalCriteria(inputs);
        Test.stopTest();

        Assert.isFalse(outputs[0].criteriaPassed);
    }

    @isTest
    public static void checkApprovalCriteriaTestException() {
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];
        List<PPA_CheckApprovalCriteriaFromFlow.Outputs> outputs = new List<PPA_CheckApprovalCriteriaFromFlow.Outputs>();
        List<PPA_CheckApprovalCriteriaFromFlow.Inputs> inputs = new List<PPA_CheckApprovalCriteriaFromFlow.Inputs>();
        PPA_CheckApprovalCriteriaFromFlow.Inputs input = new PPA_CheckApprovalCriteriaFromFlow.Inputs();

        input.priceListId = priceList.Id;
        input.whereClause = 'TEST_Field < 500000';
        inputs.add(input);

        Test.startTest();
        outputs = PPA_CheckApprovalCriteriaFromFlow.checkApprovalCriteria(inputs);
        Test.stopTest();

        Assert.isFalse(outputs[0].criteriaPassed);
    }
}