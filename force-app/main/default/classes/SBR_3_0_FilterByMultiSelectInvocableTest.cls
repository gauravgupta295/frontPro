/*********************************************************************************************************************
* Apex Class: SBR_3_0_FilterByMultiSelectInvocableTest
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description Test methods for SBR_3_0_FilterByMultiSelectInvocable
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                      DATE                 DETAIL FEATURES
    1.0         Evan Kuminski, Salesforce           2023-12-19           Initial version
    2.0         Shilpa Mitra                        2024-05-30           Increased coverage and fixed PMD issue
*********************************************************************************************************************/
@SuppressWarnings(
  'PMD.ClassNamingConventions'
)
@IsTest
private class SBR_3_0_FilterByMultiSelectInvocableTest {
    @IsTest
    static void allowedValuesStringTest() {
        SBR_3_0_FilterByMultiSelectInvocable.SBR_3_0_FilterInfo filterInfo = new SBR_3_0_FilterByMultiSelectInvocable.SBR_3_0_FilterInfo();
        filterInfo.records = new List<Asset>{
                new Asset(SM_PS_Company_Code__c='01'),
                new Asset(SM_PS_Company_Code__c='02'),
                new Asset(SM_PS_Company_Code__c='01;02')
        };
        filterInfo.fieldApiName = 'SM_PS_Company_Code__c';
        filterInfo.allowedValuesString = '01';

        List<List<SObject>> results;

        Test.startTest();
        {
            results = SBR_3_0_FilterByMultiSelectInvocable.filterByMultiSelect(new List<SBR_3_0_FilterByMultiSelectInvocable.SBR_3_0_FilterInfo>{filterInfo});
        }
        Test.stopTest();

        Assert.areEqual(1, results.size(),'Wrapper Data is not as expected');
        Assert.areEqual(2, results[0].size(),'Asset Data is not as expected');
        Assert.isTrue((String)results[0][0].get('SM_PS_Company_Code__c') == '01' || (String)results[0][0].get('SM_PS_Company_Code__c') == '01;02','Company Code doesnot match');
        Assert.isTrue((String)results[0][1].get('SM_PS_Company_Code__c') == '01' || (String)results[0][1].get('SM_PS_Company_Code__c') == '01;02','Company Code doesnot match');
        Assert.areNotEqual(results[0][0].get('SM_PS_Company_Code__c'), results[0][1].get('SM_PS_Company_Code__c'),'Company Code is matching');
    }

    @IsTest
    static void allowedValuesListTest() {
        SBR_3_0_FilterByMultiSelectInvocable.SBR_3_0_FilterInfo filterInfo = new SBR_3_0_FilterByMultiSelectInvocable.SBR_3_0_FilterInfo();
        filterInfo.records = new List<Product2>{
                new Product2(Company_Code__c='01'),
                new Product2(Company_Code__c='02'),
                new Product2(Company_Code__c='01;02')
        };
        filterInfo.fieldApiName = 'Company_Code__c';
        filterInfo.allowedValuesList = new List<String>{'01'};

        List<List<SObject>> results;

        Test.startTest();
        {
            results = SBR_3_0_FilterByMultiSelectInvocable.filterByMultiSelect(new List<SBR_3_0_FilterByMultiSelectInvocable.SBR_3_0_FilterInfo>{filterInfo});
        }
        Test.stopTest();

        Assert.areEqual(1, results.size(),'Wrapper Data is not as expected');
        Assert.areEqual(2, results[0].size(),'Asset Data is not as expected');
        Assert.isTrue((String)results[0][0].get('Company_Code__c') == '01' || (String)results[0][0].get('Company_Code__c') == '01;02','Company Code doesnot match');
        Assert.isTrue((String)results[0][1].get('Company_Code__c') == '01' || (String)results[0][1].get('Company_Code__c') == '01;02','Company Code doesnot match');
        Assert.areNotEqual(results[0][0].get('Company_Code__c'), results[0][1].get('Company_Code__c'),'Company Code is matching');
    }
}