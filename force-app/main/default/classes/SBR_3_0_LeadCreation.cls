/*********************************************************************************************************************
* Apex Class: SBR_3_0_LeadCreation
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to allow Create Leads flow to bypass duplicate alerts when creating new Leads
* - SAL-178
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-07-28         Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_LeadCreation {

    private Static string LEAD_STATUS = 'New';
    private Static string LEAD_SOURCE = 'Sales Campaign';
    private Static string LEAD_DESCRIPTION = 'Campaign Lead';
    private Static string LEAD_LASTNAME = 'Campaign Contact';
    @InvocableMethod(
      label='Create Leads'
      description='Create Leads from List of Leads passed from Create Leads flow'
    )
    public static List<LeadCreationResponse> createLeads(
      List<LeadCreationRequest> requests
    ) {
      List<LeadCreationResponse> results = new List<LeadCreationResponse>();
      LeadCreationResponse result = new LeadCreationResponse();
      result.errorOccured = false;
      result.ErrorMessages = new List<String>();
      Savepoint sp = Database.setSavepoint();
      
      if (requests.size() > 0) {
        LeadCreationRequest request = requests.get(0);
        Set<Id> accountsThatNeedDummyContact = new Set<Id>();
        Set<Id> accountIdsToCreateDummyContact = new Set<id>();
        Map<Id, Contact> dummyContactMap = new Map<Id, Contact>();
        List<Contact> existingDummyContacts = new List<Contact>();
        List<Contact> dummyContactsToCreate = new List<Contact>();
        List<Contact> allDummyContacts = new List<Contact>();
        List<Account> accountsToCreateDummyContact = new List<Account>();
        Contact newDummyContact = new Contact();
        Contact dummyContactToAssign = new Contact();
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        
        // List<Contact> dummyContactList = [SELECT Id, AccountId, FirstName, LastName FROM Contact WHERE Name = 'Campaign Contact'];
        // Contact dummyContact = new Contact();
        // Account dummyAccount = new Account();
        // String accountId = '';

        // if (dummyContactList.size() > 0) {
        //   dummyContact = dummyContactList[0];
        //   accountId = dummyContact.AccountId;
        // }
        // else {
        //   List<Account> dummyAccountList = SBR_3_0_TestDataFactory.createAccounts(1, false);
        //   dummyAccount = dummyAccountList[0];
        //   dummyAccount.Name = 'Campaign Account';
        //   dummyAccount.BillingState = 'California';
        //   dummyAccount.BillingCountry = 'United States';
        //   insert dummyAccount;

        //   dummyContactList = SBR_3_0_TestDataFactory.createContacts(1, dummyAccount.Id, false);
        //   dummyContact = dummyContactList[0];
        //   dummyContact.LastName = 'Contact';
        //   dummyContact.FirstName = 'Campaign';
        //   dummyContact.MailingCountry = 'United States';
        //   dummyContact.MailingState = 'California';
        //   insert dummyContact;
        //   accountId = dummyAccount.Id;
        // }
      for (Lead requestLead : request.Leads){
        if (requestLead.Account__c != null && !String.isBlank(requestLead.Account__c)) {
          if (requestLead.Contact__c == null || String.isBlank(requestLead.Contact__c)) {
            if (requestLead.LastName == null || String.isBlank(requestLead.LastName)) {
              accountsThatNeedDummyContact.add(requestLead.Account__c);
            }
          }
        }
      }
      existingDummyContacts = [SELECT Id, AccountId, FirstName, LastName FROM Contact WHERE AccountId IN: accountsThatNeedDummyContact AND LastName =: LEAD_LASTNAME];

      accountIdsToCreateDummyContact = accountsThatNeedDummyContact;

      for (Contact dummy : existingDummyContacts) {
        accountIdsToCreateDummyContact.remove(dummy.AccountId);
      }

      accountsToCreateDummyContact = [SELECT Id, Name FROM Account WHERE Id IN: accountIdsToCreateDummyContact];

      for (Account acct : accountsToCreateDummyContact) {
        newDummyContact = SBR_3_0_TestDataFactory.createContacts(1, acct.Id, false)[0];
        newDummyContact.FirstName = acct.Name;
        newDummyContact.LastName = LEAD_LASTNAME;
        dummyContactsToCreate.add(newDummyContact);
      } 
      List<Database.SaveResult> contactSrs = Database.insert(dummyContactsToCreate, dml);  

      allDummyContacts.addAll(existingDummyContacts);
      allDummyContacts.addAll(dummyContactsToCreate);

      for (Contact contact : allDummyContacts) {
        dummyContactMap.put(contact.AccountId, contact);
      }


      for (Lead requestLead : request.leads){

        if ((requestLead.Account__c == null || String.isBlank(requestLead.Account__c)) && (requestLead.Contact__c == null || String.isBlank(requestLead.Contact__c))){
          if (requestLead.LastName == null || String.isBlank(requestLead.LastName)) {
            requestLead.LastName = LEAD_LASTNAME;
            if(requestLead.FirstName == null || String.isBlank(requestLead.FirstName)) {
              requestLead.FirstName = requestLead.Company;
              }
            }
          }
          else if (requestLead.Account__c != null && !String.isBlank(requestLead.Account__c)) {
            if (requestLead.Contact__c == null || String.isBlank(requestLead.Contact__c)) {
              if (requestLead.LastName == null || String.isBlank(requestLead.LastName)) {
                dummyContactToAssign = dummyContactMap.get(requestLead.Account__c);
                System.debug('last name: ' + dummyContactToAssign.LastName);
                requestLead.LastName = dummyContactToAssign.LastName;
                requestLead.FirstName = dummyContactToAssign.FirstName;
                requestLead.Contact__c = dummyContactToAssign.Id;
              }
            }
          }
          requestLead.Status = LEAD_STATUS;
          requestLead.LeadSource = LEAD_SOURCE;
          requestLead.Source_Campaign__c = request.campaignId;
          requestLead.Description = requestLead.Company + LEAD_DESCRIPTION;
        }
  
        try {
          List<Database.SaveResult> srs = Database.insert(request.leads, dml);
          List<Database.Error> errors = new List<Database.Error>();
          for (Database.SaveResult sr : srs) {
            errors.addAll(sr.getErrors());
            system.debug('Success ' + sr.isSuccess());
            if(!result.errorOccured) {
              result.errorOccured = !sr.isSuccess();
            }
          }

          if (errors.size() > 0 ) {
            for (Database.Error error : errors){
              System.debug('Error message: ' + error.getMessage());
              System.debug('Fields: ' + error.getFields());
              result.ErrorMessages.add(error.getMessage());
            }
          }
        }
        catch (Exception e) {
          System.debug('Error message: ' + e.getMessage());
        }
          result.leads = request.leads;
        results.add(result);
      }
      if (result.errorOccured) {
        Database.rollback(sp);
      }
      return results;
    }
  
    public class LeadCreationRequest {
      @InvocableVariable(label='Leads to Insert' required=true)
      public List<Lead> leads;

      @InvocableVariable(label='Campaign Id' required=false)
      public string campaignId;
    }

    public class LeadCreationResponse {
        @InvocableVariable(label='Inserted Leads' required=true)
        public List<Lead> Leads;
        @InvocableVariable(label='Error messages' required=false)
        public List<String> ErrorMessages;
        @InvocableVariable(label='Error Has Occured' required = false)
        public Boolean errorOccured;
      }
  
    public class LeadCreationException extends Exception {
    }
}