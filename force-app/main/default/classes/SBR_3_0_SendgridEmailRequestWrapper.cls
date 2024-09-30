/*********************************************************************************************************************
* Apex Class: SBR_3_0_SendgridEmailRequestWrapper
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Email Wrapper class
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Piyush Jindal           2023-11-15          Initial version
    2.0         Piyush Jindal           2023-11-15          Added Wrapper classes based on new Request Payload
    3.0         Chinmay Bhatkal         2024-06-27          Code Coverage
---------------------------------------------------------------------------------------------------------------------------------------
Note:-
* 
*********************************************************************************************************************/
public with sharing class SBR_3_0_SendgridEmailRequestWrapper {
    public Integer activityType { get; set;}    
    public CommunicationData communicationData { get; set;}
    public EmailDetails emailDetails { get; set;}
    public List<AttachmentWrapper> attachments { get; set;}

    public class EmailWrapper{
        public List<String> toAddresses { get; set;}
        public String recordId { get; set;}
        public WorkOrderWrapper workOrderDetails { get; set;}
        public List<AttachmentWrapper> attachmentData { get; set;}
    }

    public class CommunicationData {
        public WorkOrderWrapper workOrderData { get; set;}
        public EmailSenderWrapper senderDetails { get; set;}
    }

    public class WorkOrderWrapper {
        public String workOrderNumber { get; set;}
        public String recordTypeC { get; set;}
        public String jobLocationC { get; set;}
        public String poNumberC { get; set;}
    }

    public class EmailDetails {
        public List<String> toEmailAddresses { get; set;}
    }

    public class EmailSenderWrapper {
        public String senderName { get; set;}
        public String senderBranchC { get; set;}
        public String senderPhone { get; set;}
        public String senderFax { get; set;}
    }

    public class AttachmentWrapper{
        public String fileContent { get; set;}
        public String fileName { get; set;}
        public Integer disposition { get; set;}
        public String mimeType { get; set;}
    }
}