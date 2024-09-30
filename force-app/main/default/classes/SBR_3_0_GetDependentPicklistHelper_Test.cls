/*********************************************************************************************************************
* Apex Class: SBR_3_0_GetDependentPicklistHelper_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_GetDependentPicklistHelper
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
    1.0          2023-04-27          Initial version    
**********************************************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_GetDependentPicklistHelper_Test {
    
        @isTest
        static void testGetDependentOptions(){           

            Schema.DescribeFieldResult countryResult = User.Countrycode.getDescribe();
            List<Schema.PicklistEntry> countryEntries = countryResult.getPicklistValues();
            Schema.DescribeFieldResult stateResult = User.statecode.getDescribe();
            List<Schema.PicklistEntry> stateEntries = stateResult.getPicklistValues();
    
            Test.startTest();
            Map<String, Set<String>> countryStatePicklist = SBR_3_0_GetDependentPicklistHelper.getDependentOptions(stateEntries, countryEntries);
            Test.stopTest();

            Set<String> usStates = new Set<String>();
            Set<String> caStates = new Set<String>();
            for(String str : countryStatePicklist.keyset()){
                if(str == 'US'){
                    usStates = countryStatePicklist.get('US');
                }
                else if(str == 'CA'){
                    caStates = countryStatePicklist.get('CA');
                }
            } 
            Assert.isTrue(usStates.contains('VA'));
            Assert.isTrue(caStates.contains('ON'));           

        }

  

       
    
}