/*********************************************************************************************************************
* Apex Class: SBR_3_0_AccountOperationsFrontLine
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to manage FrontLine trigger logic for Accounts
* - FRONT-3840, FRONT-3841, FRONT-1662, FRONT1683
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME                        DATE                DETAIL FEATURES
1.0         Kishore Meesala                   2023-08-08              Initial version 
2.0			Kishore Meesala					  2023-08-22			Added updateJobsiteAddressForNCAccounts() 
3.0			Pratiksha Kadam					  2023-08-28			Added checkAccount(),syncAccountWithRM() 
4.0 		Abhi Chauhan					  2023-08-31			Added Method to Update RM Cash Number and RM Cash State
5.0         Neeraj Kumar                      2023-09-13            Added method to create primary contact for NC accounts from RM
***********************************************************************************************************************************/

public without sharing class SBR_3_0_AccountOperationsFrontLine {
  /****************************************************************************************************
   * FRONT-3840, FRONT-3841 : create default shared job location and job site records for Non credit Accounts
   * ***************************************************************************************************/
  public static void createLocationAndJobSite(
    List<Account> newList,
    Map<Id, Account> oldMap
  ) {
    Map<Id, Account> eligibleAccounts = new Map<Id, Account>();
    List<Account> nonCreditAccountsForLocations = new List<Account>();
    for (Account acc : newList) {
      if (
        acc.recordTypeId == SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID &&
        (oldMap == null ||
        (oldMap != null &&
        oldMap.get(acc.Id) != null &&
        oldMap.get(acc.Id).recordTypeId != acc.recordTypeId))
      ) {
        nonCreditAccountsForLocations.add(acc);
        eligibleAccounts.put(acc.Id, acc);
      }
    }

    if (!nonCreditAccountsForLocations.isEmpty()) {
      Map<Id, Schema.location> accountIdAndLocationMap = createSharedLocationForNCAccounts(
        nonCreditAccountsForLocations
      );
      insert (List<Schema.location>) accountIdAndLocationMap.values();
      Map<Id, AssociatedLocation> accIdAndJobSiteMap = createJobSiteForNCAccounts(
        accountIdAndLocationMap,
        eligibleAccounts
      );
      insert (List<AssociatedLocation>) accIdAndJobSiteMap.values();
    }
  }

  public static Map<Id, Schema.location> createSharedLocationForNCAccounts(
    List<Account> nonCreditAccounts
  ) {
    Map<Id, Schema.location> accountIdAndLocationMap = new Map<Id, Schema.location>();
    for (Account acc : nonCreditAccounts) {
      Schema.location sharedLoc = SBR_3_0_SalesHelper.createJobLocFromBillingAddr(
        acc
      );
      sharedLoc.Name = acc.BillingStreet + ' ' + acc.BillingState;
      sharedLoc.State__c = acc.Driver_s_License_State__c;
      sharedLoc.Company_Code__c = SBR_3_0_UserDA.getUserById(
          UserInfo.getUserId()
        )
        .CompanyName;
      accountIdAndLocationMap.put(acc.Id, sharedLoc);
    }

    return accountIdAndLocationMap;
  }

  public static Map<Id, AssociatedLocation> createJobSiteForNCAccounts(
    Map<Id, Schema.location> accountIdAndLocationMap,
    Map<Id, Account> idAndAccountMap
  ) {
    Map<Id, AssociatedLocation> accIdAndJobSiteMap = new Map<Id, AssociatedLocation>();
    for (Id accId : accountIdAndLocationMap.keySet()) {
      Schema.location sharedLoc = accountIdAndLocationMap.get(accId);
      List<User_Location__c> userLocList = SBR_3_0_UserLocationDA.getUserLocation(
        UserInfo.getUserId()
      );
      if (userLocList != null && !userLocList.isEmpty()) {
        AssociatedLocation jobSite = SBR_3_0_SalesHelper.createJoSiteFromBillingAddr(
          IdAndAccountMap.get(accId),
          sharedLoc.Id,
          userLocList[0].Branch__c
        );
        jobSite.Status__c = 'A';
        jobSite.State__c = sharedLoc.State__c;
        //jobSite.Name__c =  (IdAndAccountMap.get(accId).Name +'-'+ sharedLoc.Name).substring(0, 50);
        jobSite.Name__c =
          IdAndAccountMap.get(accId).Name +
          '-' +
          sharedLoc.Name;
        //To complete the Job_Number field while running the test class.
        if (Test.isRunningTest()) {
          jobSite.Job_Number__c = '1234';
        }
        SBR_3_0_AssociatedLocationOperations.truncateJobNumber(jobSite);
        truncateJobName(jobSite);
        accIdAndJobSiteMap.put(accId, jobSite);
      }
    }
    return accIdAndJobSiteMap;
  }
  /********************************************************************************************************
   * FRONT-1662, FRONT16832 : Update default shared job location and job site records of the Non credit Account
   * when it's Billing address is updated
   * *******************************************************************************************************/
  public static void updateJobsiteAddressForNCAccounts(
    List<Account> newList,
    Map<Id, Account> oldMap
  ) {
    if (oldMap != null) {
      Set<Id> accIdList = new Set<Id>();
      for (Account acct : newList) {
        Account oldRec = oldMap.get(acct.Id);
        if (
          acct.recordTypeId == SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID &&
          oldRec != null &&
          oldRec.recordTypeId == acct.recordTypeId &&
          (oldRec.BillingStreet != acct.BillingStreet ||
          oldRec.BillingCity != acct.BillingCity ||
          oldRec.BillingState != acct.BillingState ||
          oldRec.BillingPostalCode != acct.BillingPostalCode ||
          oldRec.BillingCountry != acct.BillingCountry)
        ) {
          accIdList.add(acct.Id);
        }
      }

      if (!accIdList.isEmpty()) {
        List<Account> acctsWithJobsites = SBR_3_0_AccountDA.getAccountDefaultLocationAndJobsite(
          accIdList
        );
        if (acctsWithJobsites != null) {
          List<AssociatedLocation> jobSitesToUpdate = new List<AssociatedLocation>();
          Map<Id, Account> locIdAndAccMap = new Map<Id, Account>();
          for (Account acc : acctsWithJobsites) {
            if (
              acc.AssociatedLocations != null &&
              !acc.AssociatedLocations.isEmpty()
            ) {
              AssociatedLocation js = acc.AssociatedLocations[0];
              locIdAndAccMap.put(js.LocationId, acc);
              js.Job_Number__c = acc.BillingStreet;
              js.Street_Address__c = acc.BillingStreet;
              js.City__c = acc.BillingCity;
              js.State__c = acc.BillingState;
              js.Zip_Code__c = acc.BillingPostalCode;
              js.Country__c = acc.BillingCountry;
              js.Name__c =
                acc.Name +
                '-' +
                acc.BillingStreet +
                ' ' +
                acc.BillingState;
              js.Latitude_Longitude__Latitude__s = acc.BillingLatitude;
              js.Latitude_Longitude__Longitude__s = acc.BillingLongitude;
              SBR_3_0_AssociatedLocationOperations.truncateJobNumber(js);
              truncateJobName(js);
              jobSitesToUpdate.add(js);
            }
          }
          List<Schema.Location> locationsLst = [
            SELECT Id, Company_Code__c
            FROM Location
            WHERE Id IN :locIdAndAccMap.keyset()
          ];
          List<Schema.Location> locationsToUpdate = new List<Schema.Location>();
          if (locationsLst != null && !locationsLst.isEmpty()) {
            for (Schema.Location loc : locationsLst) {
              Account acc = locIdAndAccMap.get(loc.Id);
              Schema.location sharedLoc = SBR_3_0_SalesHelper.createJobLocFromBillingAddr(
                acc
              );
              sharedLoc.Id = loc.Id;
              sharedLoc.Name = acc.BillingStreet + ' ' + acc.BillingState;
              sharedLoc.State__c = acc.BillingState;
              locationsToUpdate.add(sharedLoc);
            }
          }
          if (!locationsToUpdate.isEmpty()) {
            update locationsToUpdate;
          }
          if (!jobSitesToUpdate.isEmpty()) {
            update jobSitesToUpdate;
          }
        }
      }
    }
  }

  public static void truncateJobName(AssociatedLocation al) {
    System.debug(
      '\n @@ associatedLocation.Name__c ' + associatedLocation.Name__c
    );
    if (!String.IsBlank(al.Name__c)) {
      String jobName = al.Name__c;
      if (jobName.length() > 50) {
        al.Name__c = jobName.substring(0, 50);
      }
    }
  }

  //START: FRONT-4951
  public static void checkAccount(
    List<Account> accLst,
    Map<Id, Account> newAccMap,
    Map<Id, Account> oldAccMap,
    String operation
  ) {
    Account acc = accLst[0];

    if (
      oldAccMap != null &&
      oldAccMap.get(acc.ID).recordTypeId ==
      SBR_3_0_Constants.ACCOUNT_PROSPECT_RT_ID &&
      newAccMap.get(acc.ID).recordTypeId ==
      SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID
    ) {
      SBR_3_0_API_SyncAccount.parameterDetails inputListElement = new SBR_3_0_API_SyncAccount.parameterDetails();
      List<SBR_3_0_API_SyncAccount.parameterDetails> inputList = new List<SBR_3_0_API_SyncAccount.parameterDetails>();
      inputListElement.AccountID = acc.Id;
      inputListElement.operation = 'POST';
      inputList.add(inputListElement);
      SBR_3_0_API_SyncAccount.SyncAccountRMCallout(inputList);
    } else if (acc.recordTypeId == SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID) {
      if (operation == 'POST') {
        SBR_3_0_API_SyncAccount.parameterDetails inputListElement = new SBR_3_0_API_SyncAccount.parameterDetails();
        List<SBR_3_0_API_SyncAccount.parameterDetails> inputList = new List<SBR_3_0_API_SyncAccount.parameterDetails>();
        inputListElement.AccountID = acc.Id;
        inputListElement.operation = 'POST';
        inputList.add(inputListElement);
        SBR_3_0_API_SyncAccount.SyncAccountRMCallout(inputList);
      } else if (operation == 'PUT') {
        syncAccountWithRM(accLst, newAccMap, oldAccMap);
      }
    }
  }

  public static void updateNonCredit(Map<Id, Account> newAccountMap) {
    for (Account acc : newAccountMap.values()) {
      if (
        !System.isFuture() &&
        acc.RecordTypeId == SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID &&
        acc.Non_Credit_Integration_Status__c
      ) {
        acc.Non_Credit_Integration_Status__c = false;
      }
    }
  }

  public static void syncAccountWithRM(
    List<Account> accLst,
    Map<Id, Account> newAccMap,
    Map<Id, Account> oldAccMap
  ) {
    Account oldAccount = oldAccMap.get(Trigger.new[0].ID);
    Account newAccount = newAccMap.get(Trigger.new[0].ID);

    SBR_3_0_API_SyncAccount.parameterDetails inputListElement = new SBR_3_0_API_SyncAccount.parameterDetails();
    List<SBR_3_0_API_SyncAccount.parameterDetails> inputList = new List<SBR_3_0_API_SyncAccount.parameterDetails>();

    inputListElement.AccountID = newAccount.Id;
    inputListElement.operation = 'PUT';
    inputList.add(inputListElement);
    SBR_3_0_API_SyncAccount.SyncAccountRMCallout(inputList);
  }
  //END : FRONT-4951
  //START: FRONT-4951
  public static void updateRMCashNumberState(
    List<Account> accLst,
    Map<Id, Account> oldAccMap
  ) {
    for (Account acc : accLst) {
      //FRONT-9890 START
      if (
        oldAccMap == null ||
        (oldAccMap.get(acc.Id).RecordTypeId ==
        SBR_3_0_Constants.ACCOUNT_PROSPECT_RT_ID &&
        acc.RecordTypeId == SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID)
      ) {
        //FRONT-9890 END
        if (acc.RecordTypeId == SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID) {
          acc.RM_Cash_Number__c = acc.Drivers_License__c;
          acc.RM_Cash_State__c = acc.Driver_s_License_State__c;
          acc.AccountNumber = acc.RM_Cash_State__c + acc.RM_Cash_Number__c; //FRONT-10075
        }
      }
    }
  }
  //END : FRONT-4951
  //START : FRONT-7377
  public static void createPrimaryContact(List<Account> accList) {
    List<Contact> conList = new List<Contact>();
    String accNameRegex = System.Label.Account_Name_Regex;
    Pattern regex = Pattern.compile(accNameRegex);
    for (Account acc : accList) {
      if (acc.recordTypeId == SBR_3_0_Constants.ACCOUNT_NON_CREDIT_RT_ID) {
        Contact con = new Contact();
        con.AccountId = acc.Id;
        Matcher matcher = regex.matcher(acc.Name);
        if (matcher.matches()) {
          con.FirstName = acc.Name.substringAfter(',');
          con.LastName = acc.Name.substringBefore(',');
        } else {
          con.LastName = acc.Name;
        }
        con.Email = acc.E_mail_Address__c;
        con.MailingCity = acc.BillingCity;
        con.MailingState = acc.BillingState;
        con.MailingStreet = acc.BillingStreet;
        con.MailingPostalCode = acc.BillingPostalCode;
        con.MailingCountry = acc.BillingCountry;
        Con.Phone = acc.Phone;
        Con.Drivers_License__c = acc.Drivers_License__c;
        Con.Drivers_License_State__c = acc.Driver_s_License_State__c;
        con.Primary_Contact__c = true;
        conList.add(con);
      }
    }
    if (!conList.isEmpty()) {
      insert conList;
    }
  }
  //END : FRONT-7377
}