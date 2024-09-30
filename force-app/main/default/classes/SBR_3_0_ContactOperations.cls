/******************************************************************************************
* Apex Class: SBR_3_0_ContactOperations
-------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Contains utility methods used during:
* -   Creation/Update of Contacts
-------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          	DATE            DETAIL FEATURES
    1.0         Philippe Bilodeau           2023-03-17      Initial version
*******************************************************************************************/
public class SBR_3_0_ContactOperations {
	/***********************************************************************************
    * Description: Populates the parent account on Contact records
    ************************************************************************************/
    public static void populateParentAccountOnContact(List<Contact> contactsList)
    {
        Map<Id, Account> accountIdToAccountMap = new Map<Id, Account>();
        for (Contact c : contactsList)
        {
            if (c.AccountId != null)
            {
                accountIdToAccountMap.put(c.AccountId, null);
            }
        }
        accountIdToAccountMap = SBR_3_0_AccountDA.getAccounts(accountIdToAccountMap.keySet());
        for (Contact c : contactsList)
        {
            if (c.AccountId != null) {
                Account a = accountIdToAccountMap.get(c.AccountId);
                if (a.ParentId != null && c.AccountParent__c != a.ParentId)
                {
                    c.AccountParent__c = a.ParentId;
                }

                // SF-5397
                if(String.isBlank(c.Account_Record_Type_Txt__c)) {
                    c.Account_Record_Type_Txt__c = a.RecordType.Name;
                }
            }
        }
    }
}