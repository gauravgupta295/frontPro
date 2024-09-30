public with sharing class SBR_3_0_SendgridWrapper {
    public Integer activityType { get; set;}
    public CommunicationData communicationData { get; set;}
    public EmailDetails emailDetails { get; set;}

    public class CommunicationData {
        public String ccaUrl { get; set;}
        public String lastName { get; set;}
        public String fullName { get; set;}
        public String accountNumber { get; set;}
        public String creditManagerPhone { get; set;}
        public String creditManagerEmail { get; set;}
        public String creditManagerName { get; set;}
        public String personalizedText { get; set;}
    }

    public class EmailDetails {
        public List<String> toEmailAddresses { get; set;}
        public String subject { get; set;}         
    }

    public class EmailWrapper{
        public String addContact { get; set;}
        public List<String> toAddress { get; set;}
        public String frm { get; set;}
        public List<String> bcc { get; set;}
        public String subject { get; set;}
        public String body { get; set;}
        public String recId { get; set;}
        public String frmName { get; set;}
    }

}