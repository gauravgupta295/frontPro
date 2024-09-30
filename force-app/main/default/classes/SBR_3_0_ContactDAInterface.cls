/*********************************************************************************************************************
* Apex Class: SBR_3_0_ContactDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Contact Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-16            Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_ContactDAInterface {
    Map<Id, Contact> getContactsName(Set<Id> ids);
    Map<Id, Contact> getContacts(Set<Id> ids);
    List<Contact> getContacts();
    List<Contact> getContactsWithAccId(String accountId);
    List<Contact> getContact(SBR_3_0_ContactWrap c);
}