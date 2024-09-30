/*********************************************************************************************************************
* Apex Class: SBR_3_0_ConvertLeads
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage Lead Conversion
* - SAL-326
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-02            Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_ConvertLeads {
    
    @InvocableMethod(label='Convert Lead' description='Convert Lead with Opportunity creation customization')
    public static List<LeadConversionWrapper> convertLead(List<LeadConversionWrapper> wrappers) {

        List<LeadConversionWrapper> result = new List<LeadConversionWrapper>();

        try {
            LeadStatus qualifiedStatus = SBR_3_0_LeadDA.getLeadStatus(SBR_3_0_Constants.LEAD_STATUS_QUALIFIED);

            if(wrappers.size() > 0) {
                
                LeadConversionWrapper wrap = wrappers.get(0);

                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(wrap.leadId);
                lc.setConvertedStatus(qualifiedStatus.ApiName);

                if(!String.isBlank(wrap.accountId)) {
                    lc.setAccountId(wrap.accountId);
                }

                if(!String.isBlank(wrap.contactId)) {
                    lc.setContactId(wrap.contactId);
                }

                if(!String.isBlank(wrap.opportunityId)) {
                    lc.setOpportunityId(wrap.opportunityId);
                } else if(wrap.createNewOpportunity == true) {
                    lc.setOpportunityName(wrap.opportunityName);
                } else {
                    lc.setDoNotCreateOpportunity(true);
                }

                Database.LeadConvertResult lcResult = Database.convertLead(lc);

                if(lcResult.isSuccess()) {
                    LeadConversionWrapper w = new LeadConversionWrapper();
                    w.leadId = lcResult.getLeadId();
                    w.accountId = lcResult.getAccountId();
                    w.contactId = lcResult.getContactId();
                    w.opportunityId = lcResult.getOpportunityId();
                    result.add(w);
                }
            }
            
        } catch (Exception ex) {
            System.StatusCode statusCode = ex.getDmlType(0);
            
            if(statusCode == getDDStatusCode()) {
                throw new LeadConversionException('The conversion process resulted in a duplicate Account, ' +
                'Contact, or Opportunity. Please review the Lead and try again.');
            }
            else {
                throw new LeadConversionException(ex.getMessage());
            }
        }

        
        return result;
    }

    public static System.StatusCode getDDStatusCode() {
        return StatusCode.DUPLICATES_DETECTED;
    }

    // if Lead Status = Qualified, convert it. Do not create a Account/Contact on conversion if Lead
    // is associated to an Account/Contact already
    public static List<Database.LeadConvertResult> convertQualifiedLeads(Map<Id, Lead> newMap) {
        List<Database.LeadConvert> leadConverts = new List<Database.LeadConvert>();
        List<Database.LeadConvertResult> results = new List<Database.LeadConvertResult>();
        
        LeadStatus qualifiedStatus = SBR_3_0_LeadDA.getLeadStatus(SBR_3_0_Constants.LEAD_STATUS_QUALIFIED);

        Map<Id, Contact> contMap = new Map<Id, Contact>();
        for(Lead l : newMap.values()) {
            if(l.Contact__c != null) {
                contMap.put(l.Contact__c, null);
            }
        }

        contMap = SBR_3_0_ContactDA.getContacts(contMap.keySet());

        for(Lead l : newMap.values()) {
            if(l.Status == SBR_3_0_Constants.LEAD_STATUS_QUALIFIED && l.IsConverted == false) {
                Database.LeadConvert lc = new Database.LeadConvert();
                lc.setLeadId(l.id);
                lc.setConvertedStatus(qualifiedStatus.ApiName);

                if(l.Account__c != null) {
                    lc.setAccountId(l.Account__c);
                }

                if(l.Contact__c != null) {
                    lc.setContactId(l.Contact__c);
                }

                // If Lead has Contact but no Account, use Contact's Account.
                if(l.Account__c == null && l.Contact__c != null) {
                    lc.setAccountId(contMap.get(l.Contact__c).AccountId);
                }

                leadConverts.add(lc);
            }
        }

        if(leadConverts.size() > 0) {
            results = Database.convertLead(leadConverts);
        }

        return results;
    }

    public class LeadConversionWrapper {
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

    public class LeadConversionException extends Exception {} 

}