/*********************************************************************************************************************
* Apex Class: SBR_3_0_ContactDA
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* @description : Concrete class for Contact Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Kunal Patel           2022-02-16            Initial version    
    2.0         Hrishikesh Kanabar    2022-07-19            Added method getContactsWithAccId
*********************************************************************************************************************/
public with sharing class SBR_3_0_ContactDA implements SBR_3_0_ContactDAInterface {
   /**
    * @description : getContantRecords
    * @param ids 
    * @return  `Map<Id, Contact>`
    */
    public static Map<Id, Contact> getContactsName(Set<Id> ids){
        return new Map<Id, Contact>([SELECT ID, Salutation, Name, FirstName, MiddleName, LastName, Suffix FROM Contact WHERE ID IN: ids WITH SECURITY_ENFORCED]);
    }

    /**
    * @description : getContantRecords
    * @param id 
    * @return  `Contact`
    */
    @AuraEnabled (Cacheable=false)
    public static Contact getContactById(Id id){
        return [SELECT ID, Salutation, Name, FirstName, MiddleName, LastName, Suffix, Phone, MobilePhone FROM Contact WHERE ID =: id WITH SECURITY_ENFORCED];
    }

    /**
     * @description : getContantRecords
     * @param ids 
     * @return  `Map<Id, Contact>`
     */
    public static Map<Id, Contact> getContacts(Set<Id> ids) {
        return new Map<Id, Contact>([SELECT ID, Name, AccountId FROM Contact WHERE ID IN: ids WITH SECURITY_ENFORCED]);
    }
    
    /**
     * @description : getContantRecords
     * @return  `List<Contact>`
     */
    public static List<Contact> getContacts() {
        return [SELECT ID, Name FROM Contact WITH SECURITY_ENFORCED];
    }
    
    /**
     * @description : getContantRecords
     * @param accountId 
     * @return  `List<Contact>`
     */
    @AuraEnabled
    public static List<Contact> getContactsWithAccId(String accountId)
    {
        List<Contact> conList=[SELECT Id, Name, FirstName, LastName, AccountId, Email FROM Contact WHERE AccountId =: accountId WITH SECURITY_ENFORCED limit 10000];
        return conList;
    }
    
    /**
     * @description : getContantRecords
     * @param accIds 
     * @param lastName 
     * @return  `List<Contact>`
     */
    public static List<Contact> getContactsByAccIdLastName(Set<Id> accIds, String lastName) {
        //gets contacts with a specific last name in the account
        return [SELECT Id, AccountId, FirstName, LastName FROM Contact WHERE AccountId IN: accIds AND LastName =: lastName WITH SECURITY_ENFORCED];
    }
    
    /**
     * @description : getContantRecords
     * @param c 
     * @return  `List<Contact>`
     */
    public static List<Contact> getContact(SBR_3_0_ContactWrap c) {
        List<Contact> contacts = new List<Contact>();
        List<String> fieldNames = new List<String>();
        fieldNames.add('lastName');
        if(!String.isBlank(c.firstName)) {
            fieldNames.add('firstName');
        }
        if(!String.isBlank(c.email)) {
            fieldNames.add('email');
        }
        if(!String.isBlank(c.phone)) {
            fieldNames.add('phone');
        }
        String query=
                ' SELECT ' 
                + String.escapeSingleQuotes(String.join(fieldNames, ',' )) 
                +' FROM Contact ' ;
        contacts = Database.query(query); //NOPMD
        return contacts;
    }
    /**
     * @description : getContantRecords
     * @param c 
     * @param acct 
     * @return  `List<Contact>`
     */
    public static List<Contact> getContact(SBR_3_0_ContactWrap c, Account acct) {
        List<Contact> contacts = new List<Contact>();
        List<String> fieldNames = new List<String>();
        String firstName='';
        // PS-4522:SG - Begin: special characters are coming in as Unicode values in First & Last Name, and needs to be escaped to do a lookup of a contact record.
        fieldNames.add('lastName');
		fieldNames.add('firstName');
        c.lastName = c?.lastName?.trim()??'';
        firstName = c?.firstName?.trim()??'';
        String nameToCheck = c.lastName+', '+firstName;
        nameToCheck = nameToCheck.escapeUnicode().replace('\'', '\\\'');
        // PS-4522:SG - End: 
        if(nameToCheck.length() > 20){
            nameToCheck = nameToCheck.substring(0, 20).toLowerCase();
        }    
        String emailFilter = '';
        if(!String.isBlank(c.email)) {
            fieldNames.add('email');
            emailFilter = ' AND email = \''+ c.email +'\' ';
        }
        String phoneFilter = '';
        if(!String.isBlank(c.phone)) {
            fieldNames.add('phone');
            phoneFilter = ' AND phone = \''+ c.phone +'\' ';
        }
         String query=
            ' SELECT ' 
                + String.escapeSingleQuotes(String.join(fieldNames, ',' )) 
                +' FROM Contact WHERE AccountId = \''+acct.Id + '\''
             	+' AND RM_Contact_Name__c = \''+nameToCheck+'\''
                + emailFilter 
                + phoneFilter;
        contacts = Database.query(query); //NOPMD
        return contacts;
    }
     
      //p2p-5261 START
     public static List<Contact> p2pGetContact(SBR_3_0_ContactWrap c, Account acct) {
        system.debug('p2p start get contact');
        List<Contact> contacts = new List<Contact>();
        List<String> fieldNames = new List<String>();
        String firstName='';
        fieldNames.add('lastName');  
        if(!String.isBlank(c.firstName)) {
            fieldNames.add('firstName');
            firstName=c.firstName.trim();
        }



        String nameToCheck = c.lastName.trim()+', '+firstName;
        if(nameToCheck.length() > 20){
            nameToCheck = nameToCheck.substring(0, 20);
        }    
        String emailFilter = '';
        if(!String.isBlank(c.email)) {
            fieldNames.add('email');
            emailFilter = ' AND (email = \''+ c.email +'\' ';
        }
        String phoneFilter = '';
        if(!String.isBlank(c.phone)) {
            fieldNames.add('phone');
            phoneFilter = ' OR phone = \''+ c.phone +'\' )';
        }
         String query=
                ' SELECT ' 
                + String.escapeSingleQuotes(String.join(fieldNames, ',' )) 
                +' FROM Contact WHERE AccountId = \''+acct.Id + '\''
             	+' AND RM_Contact_Name__c = \''+nameToCheck+'\''
                + emailFilter 
                + phoneFilter;
        system.debug( 'p2p ' + query);
        contacts = Database.query(query);
                system.debug('p2p end get contact');

        return contacts;
    }
    //P2P-5261 END
 }