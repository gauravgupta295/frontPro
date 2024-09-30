@istest
public class SBR_3_0_GetDynamicDataForDatatableTest {
    
    @isTest
    static void testGetDynamicDataFunctionality(){
        OperatingHours oh = new OperatingHours(Name='TEST_Hours1',TimeZone='America/Halifax');
        insert oh;
        string name  ='TestHr';
        ServiceTerritory testST= new ServiceTerritory(Name=name,OperatingHoursId=oh.Id,IsActive=true,Branch_Location_Number__c = '1234',CountryCode = 'US');
        insert testST;
        WorkOrder wo = SBR_3_0_ServiceTestDataFactory.createWorkOrder(false);
        wo.SF_PS_Expense_To_Location__c = testST.id;
        insert wo;
        SBR_3_0_GetDynamicDataForDatatable.GetWrapperOfSObjectFieldColumnActionValues('Product Consumed Number,Stock class,Description,Quantity Unit Of Measure,Quantity,Shipped Quantity,Backordered Quantity,Selling Price,Extended Amount,Labor Code',
                                                                                     'ProductConsumedNumberUrl:ProductConsumedNumber:url,SF_PS_Stock_Class__c:text,SF_PS_Description__c:text,QuantityUnitOfMeasure:text,SF_PS_Quantity__c:text,SF_PS_Shipped_Qty__c:text,SF_PS_Backordered_Qty__c:text,SF_PS_Selling_Price__c:text,SF_PS_Sub_Total__c:text,SF_PS_Labor_Code__c:text',
                                                                                     'ProductConsumedNumber,SF_PS_Stock_Class__c,SF_PS_Description__c,QuantityUnitOfMeasure,SF_PS_Quantity__c,SF_PS_Shipped_Qty__c,SF_PS_Backordered_Qty__c,SF_PS_Selling_Price__c,SF_PS_Sub_Total__c,SF_PS_Labor_Code__c',
                                                                                     'ProductConsumed',
                                                                                     'WorkOrderId',
                                                                                     wo.Id,'250');
    }

}