/*********************************************************************************************************************
* Apex Class: SBR_3_0_EmailClass_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - To test send email functinality.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Hrishikesh Kanabar      2022-07-09           Initial version    
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_EmailClass_Test {

    static testMethod void testsendEmail(){
        
        List<Account> accounts = SBR_3_0_TestDataFactory.createAccounts(1, true);
        
        String userEmail=UserInfo.getUserEmail();
        String reccId=accounts[0].id;
        // building test string
        String emailStr= '{"toAddress":["test@test.com"],"frm":"'+userEmail+'","bcc":"test@test.com","subject":"subject","body":"Body","recId":"'+reccId+'","frmName":"Name"}';

        
        Test.startTest();
        SBR_3_0_EmailClass.sendEmail(emailStr);
        // we assert by what governor limits say 
        Integer invocations = Limits.getEmailInvocations();
        System.assertEquals(1, invocations, 'Email has not been sent');
        Test.stopTest();
    }
    
    static testMethod void testinsertRichTextImageAsDocument(){
        
        List<String> srcList = new list<String> { 'https://www.google.com/' , 'https://www.google.com/'};
            
         Test.startTest();    
         list<String> modifiedUrl=SBR_3_0_EmailClass.insertRichTextImageAsDocument(srcList);
         System.assertEquals(srcList.size(),modifiedUrl.size() , 'All url not modified');
         Test.stopTest();
    }
    
    
}