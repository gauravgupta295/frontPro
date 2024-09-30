@isTest
public with sharing class PPA_GeneratePDFRequestFromFlow_Test {

    @TestSetup
    static void testSetup(){
        PPA_GeneratePDFUtility_Test.makeData();
    }

    @isTest
    public static void generateRatesPDFTest() {
        List<PPA_GeneratePDFRequestFromFlow.Inputs> inputs = new List<PPA_GeneratePDFRequestFromFlow.Inputs>();
        List<PPA_GeneratePDFRequestFromFlow.Outputs> outputs = new List<PPA_GeneratePDFRequestFromFlow.Outputs>();

        PPA_GeneratePDFRequestFromFlow.Inputs input = new PPA_GeneratePDFRequestFromFlow.Inputs();
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];

        input.priceListId = priceList.Id;
        input.customerName = 'TEST';
        input.draftTemplate = false;
        input.onlyRatesLoaded = false;
        inputs.add(input);

        outputs = PPA_GeneratePDFRequestFromFlow.generateRatesPDF(inputs);

        Assert.areEqual('0', outputs[0].errorCode);
        Assert.areEqual('Completed', outputs[0].status);
    }

    @isTest
    public static void generateRatesPDFTestException() {
        List<PPA_GeneratePDFRequestFromFlow.Inputs> inputs = new List<PPA_GeneratePDFRequestFromFlow.Inputs>();
        List<PPA_GeneratePDFRequestFromFlow.Outputs> outputs = new List<PPA_GeneratePDFRequestFromFlow.Outputs>();

        PPA_GeneratePDFRequestFromFlow.Inputs input = new PPA_GeneratePDFRequestFromFlow.Inputs();
        PPA_Price_List__c priceList = [SELECT Id FROM PPA_Price_List__c LIMIT 1];

        input.customerName = 'TEST';
        input.draftTemplate = false;
        input.onlyRatesLoaded = false;
        inputs.add(input);

        outputs = PPA_GeneratePDFRequestFromFlow.generateRatesPDF(inputs);

        Assert.areEqual('-1', outputs[0].errorCode);
    } 
}