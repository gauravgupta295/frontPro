/**
 * Created by ekuminski on 11/22/2023.
 */

@IsTest
private class SBR_3_0_TechnicalAttributeDATest {
    @IsTest
    static void getByNamesTest() {
        insert new SVMXA360__SM_TA_TechnicalAttribute__c(
                Name = 'TEST',
                SVMXA360__DeveloperName__c = 'TEST'
        );
        List<SVMXA360__SM_TA_TechnicalAttribute__c> results;
        Test.startTest();
        {
            results = new SBR_3_0_TechnicalAttributeDA().getByNames(new Set<String>{'TEST'});
        }
        Test.stopTest();

        Assert.isFalse(results.isEmpty());
    }

    @IsTest
    static void getTemplateByNameTest() {
        insert new SVMXA360__SM_TA_Template__c(
                Name = 'TEST',
                SVMXA360__DeveloperName__c = 'TEST'
        );
        SVMXA360__SM_TA_Template__c result;
        Test.startTest();
        {
            result = new SBR_3_0_TechnicalAttributeDA().getTemplateByName('TEST');
        }
        Test.stopTest();

        Assert.isNotNull(result);
    }

    @IsTest
    static void getCategoryByNameTest() {
        insert new SVMXA360__SM_TA_Category__c(
                Name = 'TEST',
                SVMXA360__DeveloperName__c = 'TEST'
        );
        SVMXA360__SM_TA_Category__c result;
        Test.startTest();
        {
            result = new SBR_3_0_TechnicalAttributeDA().getCategoryByName('TEST');
        }
        Test.stopTest();

        Assert.isNotNull(result);
    }
}