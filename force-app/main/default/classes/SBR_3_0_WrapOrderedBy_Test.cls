/*********************************************************************************************************************
* Apex Class: SBR_3_0_WrapOrderedBy_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for OrderedBy Wrapper Class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Soni Pinjala         	2023-08-24          Initial version    
*********************************************************************************************************************/
@isTest
public class SBR_3_0_WrapOrderedBy_Test {

    @isTest
    static void testSBR_3_0_WrapOrderedBy() {
        
        SBR_3_0_WrapOrderedBy orderedByWrapper = new SBR_3_0_WrapOrderedBy();
        
        orderedByWrapper.firstName = 'Jane';
        orderedByWrapper.lastName = 'Smith';
        orderedByWrapper.phone = '987-654-3210';
        orderedByWrapper.email = 'jane.smith@example.com';

        System.assertEquals('Jane', orderedByWrapper.firstName);
        System.assertEquals('Smith', orderedByWrapper.lastName);
        System.assertEquals('987-654-3210', orderedByWrapper.phone);
        System.assertEquals('jane.smith@example.com', orderedByWrapper.email);
    }
}