/*********************************************************************************************************************
* Apex Class: SBR_3_0_WrapContact_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for Contact Wrapper Class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Soni Pinjala         	2023-08-24          Initial version    
*********************************************************************************************************************/
@isTest
public class SBR_3_0_WrapContact_Test {

    @isTest
    static void testSBR_3_0_WrapContact() {
       
        SBR_3_0_WrapContact contactWrapper = new SBR_3_0_WrapContact();
        
        contactWrapper.firstName = 'John';
        contactWrapper.lastName = 'Doe';
        contactWrapper.phone = '123-456-7890';
        contactWrapper.email = 'john.doe@example.com';

        System.assertEquals('John', contactWrapper.firstName);
        System.assertEquals('Doe', contactWrapper.lastName);
        System.assertEquals('123-456-7890', contactWrapper.phone);
        System.assertEquals('john.doe@example.com', contactWrapper.email);
    }
}