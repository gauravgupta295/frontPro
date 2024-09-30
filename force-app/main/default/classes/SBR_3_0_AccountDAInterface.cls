/*********************************************************************************************************************
* Apex Class: SBR_3_0_AccountDAInterface
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Interface class for Account Data Access
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Avinash Rao             2022-03-13          Initial version    
*********************************************************************************************************************/
public interface SBR_3_0_AccountDAInterface {
    Map<Id, Account> getAccountsName(Set<Id> ids);
    Map<Id, Account> getAccounts(Set<Id> ids);
    Map<Id, Account> getAccountsByRMNumbers(Set<String> rmNumbers);
    List<Account> getAccountsFromLatLong(list<Account> lAccounts);
    Account getAccount(Id id);
    Account getAccountByRmAccountNumber(String rmAccountNumber);
    List<Account> getAccounts();
    List<Account> getAccountsByRecordTypeName(String recordTypeName);
    List<SBR_3_0_AccountDA.AccountWrapper> getTopAccounts(Id userId);
    List<SBR_3_0_AccountDA.AccountWrapper> getAccountRanks(Set<Id> accIds, Id userId);
    Map<Id, Account> getAccountReadinessFields(Set<Id> ids);
    List<Account> getAccountsLatLongStatus(Set<Id> ids);
    List<SBR_3_0_AccountDA.AccountWrapper> getAccountsFiltered(SBR_3_0_GoogleMapCmpController.FilterWrapper wrapper);
    List<AggregateResult> getAccountRelationshipsForUsers(Set<String> userIds);
    Decimal getAccountRelationshipsForUsersLowestRank(SBR_3_0_GoogleMapCmpController.FilterWrapper filterWrapper);
    String getAccountRMNumber(Id accountId, Boolean useHierarchy);
    Account getAccountRMNumberAndType(Id accountId, Boolean useHierarchy);
    String inClausify(Set<Id> ids);
}