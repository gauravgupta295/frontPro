@isTest
public class PPA_ExportDeliverCSVs_Test {

   @isTest
   static void testSendCSVsViaEmail() {
       List<Messaging.EmailFileAttachment> emailattachments = new List<Messaging.EmailFileAttachment>();
       Messaging.EmailFileAttachment fileAttachment = new Messaging.EmailFileAttachment();
       
       PPA_Admin_Config__c admConfig = new PPA_Admin_Config__c(PPA_Admin_Group_Email__c='test@test.com');
       insert admConfig;
       
       fileAttachment.fileName = 'TEST.csv';
       fileAttachment.body = Blob.valueOf('THIS IS A TEST');
       emailattachments.add(fileAttachment);

       Test.startTest();       
       PPA_ExportDeliverCSVs.sendCSVsViaEmail(1, emailattachments);
       Test.stopTest();
       
       System.assertEquals(1, emailattachments.size(), 'One email attachment should have been sent');
   }
}