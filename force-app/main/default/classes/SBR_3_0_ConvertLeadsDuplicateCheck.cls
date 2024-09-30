/*********************************************************************************************************************
* Apex Class: SBR_3_0_ConvertLeadsDuplicateCheck
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to confirm that custom lead conversion flow will not violate duplcate rules on Opp, Acc, and Contact
* - SAL-3038
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Konrad Haight           2022-05-11          Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_ConvertLeadsDuplicateCheck {
  @InvocableMethod(
    label='Convert Lead Check'
    description='Check for duplicates before converting Lead using custom LeadConvert class'
  )
  public static List<LeadConversionCheckWrapper> convertLeadCheck(
    List<LeadConversionCheckWrapper> wrappers
  ) {
    List<LeadConversionCheckWrapper> result = new List<LeadConversionCheckWrapper>();
    LeadConversionCheckWrapper w = new LeadConversionCheckWrapper();
    Savepoint sp = Database.setSavePoint();

    if (wrappers.size() > 0) {
      LeadConversionCheckWrapper wrap = wrappers.get(0);

      Set<Id> leadIds = new Set<Id>();
      leadIds.add(wrap.leadId);

      List<Lead> leads = SBR_3_0_LeadDA.getLeadsByIds(leadIds);
      Lead l = leads[0];
	  System.debug('Lead Rec : '+l);
      //Account matching
      //Get Account info from Lead in the flow
      //If duplicate account is found, then use the first match - because ideally, there won't be more than one duplicate accounts

      if (String.isBlank(wrap.accountId)) {
        Account a = getAccount(l);
        Database.SaveResult accountSaveResult = Database.insert(a, false);
        List<SObject> accountDuplicates = SBR_3_0_DuplicateResults.getDuplicatedRecords(
          accountSaveResult
        );
        if (accountDuplicates.size() > 0) {
          w.accountId = accountDuplicates[0].Id;
        } else {
          w.accountId = '';
        }
      }

      //Contact matching
      //Try to insert Contact and see if there are any duplicates
      //If Contact or Lead dups found, assign the flow variables one of the dup values

      Contact c = getContact(l);

      System.debug(c);

      Database.SaveResult contactSaveResult = Database.insert(c, false);
      List<SObject> contactDuplicates = SBR_3_0_DuplicateResults.getDuplicatedRecords(
        contactSaveResult
      );
      w.leadId = '';
      w.contactId = '';
      if (contactDuplicates.size() > 0) {
        for (SObject duplicate : contactDuplicates) {
          if (duplicate.getSObjectType() == c.getSObjectType()) {
            w.contactId = duplicate.Id;
          }
            System.debug('Duplicate SObject Type : '+duplicate.getSObjectType());
            System.debug('Lead SObject Type : '+duplicate.getSObjectType());
            System.debug('Duplicate Id : '+duplicate.Id);
            System.debug('Lead Id : '+l.Id);
          if (
            duplicate.getSObjectType() == l.getSObjectType() &&
            duplicate.Id != l.Id
          ) {
            w.leadId = duplicate.Id;
          }
        }
      }

      //Rollback DML after finding the duplicates
      Database.rollback(sp);

      //If a dup lead is found, then try to insert Contact for the original lead to bypass the dup alert on Convert Lead when a duplicate Lead exists.
      //If the lead does not have an account, create the account
      if (String.isBlank(w.contactId) && String.isNotBlank(w.leadId)) {
        Database.DMLOptions dml = new Database.DMLOptions();
        dml.DuplicateRuleHeader.AllowSave = true;
        if (String.isNotBlank(w.accountId)) {
          c.AccountId = w.accountId;
        } else if (String.isBlank(wrap.accountId)) {
          //don't override the account if it alraedy exists on lead
          Account a = getAccount(l);
          Database.SaveResult acctSaveResult = Database.insert(a, false);
          c.AccountId = a.Id;
          w.accountId = a.Id;
        } else {
          c.AccountId = wrap.accountId;
        }
        Database.SaveResult saveResult = Database.insert(c, dml);

        if (saveResult.isSuccess()) {
          w.contactId = c.Id;
        } else {
          for (Database.Error error : saveResult.getErrors()) {
            system.debug(error.getMessage());
          }
        }
      }

      System.debug(w);
      result.add(w);
    }
    return result;
  }

  public static Contact getContact(Lead l) {
    Contact c = new Contact();
    c.FirstName = l.FirstName;
    c.Title = l.Title;
    c.LastName = l.LastName;
    c.Email = l.Email;
    c.Phone = l.Phone;
    c.MobilePhone = l.MobilePhone;
    c.MailingCity = l.City;
    c.MailingStreet = l.Street;
    c.MailingState = l.State;
    c.MailingPostalCode = l.PostalCode;
    c.MailingCountry = l.Country;
    return c;
  }

  public static Account getAccount(Lead l) {
    Account a = new Account();
    a.Name = l.Company;
    a.Phone = l.Phone;
    a.Status__c = SBR_3_0_Constants.ACCOUNT_STATUS_ACTIVE;
    a.Company_Name__c = l.Company;
    a.BillingCity = l.City;
    a.BillingStreet = l.Street;
    a.BillingCountry = l.Country;
    a.BillingState = l.State;
    a.BillingPostalCode = l.PostalCode;
    return a;
  }

  public class LeadConversionCheckWrapper {
    @InvocableVariable(label='Lead ID' required=true)
    public String leadId;

    @InvocableVariable(label='Account ID' required=false)
    public String accountId;

    @InvocableVariable(label='Contact ID' required=false)
    public String contactId;

    @InvocableVariable(label='Opportunity ID' required=false)
    public String opportunityId;

    @InvocableVariable(label='Opportunity Name' required=false)
    public String opportunityName;

    @InvocableVariable(label='Create New Opportunity' required=false)
    public Boolean createNewOpportunity;
  }

  public class LeadConversionCheckException extends Exception {
  }
}