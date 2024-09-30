@SuppressWarnings(
  'PMD.ExcessiveClassLength, PMD.CyclomaticComplexity, PMD.ExcessivePublicCount, PMD.CognitiveComplexity'
)
public with sharing class SBR_3_0_POTestDataFactory {

   /**
   * @description Creates PO records for unit testing.
   * @param count The number of PO records to create.
   * @param accountId The id of the related account record.
   * @param insertRecords Boolean value indicating whether or not to insert the records.
   * @return A list of resulting PO records.
   */
  public static List<Purchase_Order__c> createPurchaseOrders(
    Integer count,
    Account acct,
    Boolean insertRecords
  ) {
    List<Purchase_Order__c> purchaseOrders = new List<Purchase_Order__c>();

    for (Integer i = 0; i < count; i++) {
      String randomString = SBR_3_0_TestDataFactory.generateRandomString(15);
      String name = randomString + String.valueOf(i);
      String randomNumber = string.valueOf(Math.abs(Crypto.getRandomLong())).substring(0, 8);
      Date today = Date.today();

      Schema.Location loc = SBR_3_0_TestDataFactory.createLocations(
      count,
      true,
      'Branch'
    )[0];

      purchaseOrders.add(
        new Purchase_Order__c(
          Name = '12345',
          Vendor__c = acct.Id,
          PO_Number__c = '12345',
          Vendor_Number__c = randomNumber,
          Vendor_Name_Text__c = acct.Name + String.valueOf(i),
          Status__c = 'Draft',
          Type__c = 'Rerent',
          Issue_Date__c = today,
          Location__c = loc.Branch_Location_Number__c,
          ShipTo__c = loc.Branch_Location_Number__c
        )
      );
    }

    insertRecords(purchaseOrders, insertRecords);

    return purchaseOrders;
  }
    
 
   /**
   * @description Creates PO Line Item records for unit testing.
   * @param count The number of PO Line records to create.
   * @param purchaseOrderId The id of the related PO record.
   * @param insertRecords Boolean value indicating whether or not to insert the records.
   * @return A list of resulting PO Line Item records.
   */
  public static List<PO_Line_Item__c> createPurchaseOrderLineItems(
    Integer count,
    Id purchaseOrderId,
    Boolean insertRecords
  ) {
   
      List<PO_Line_Item__c> lineItems = new List<PO_Line_Item__c>();
        for(Integer i = 0; i < count; i++) {
            lineItems.add(new PO_Line_Item__c(
                Purchase_Order__c = purchaseOrderId,
                Item_Type__c = 'M', 
                Quantity__c = 10,
                Status__c = 'Open'
            ));
        }
      
       insertRecords(lineItems, insertRecords);
      return lineItems;
  }
   
  /**
   * @description Creates User location for logged in user.
   */
  public static List<User_Location__c> createUserLocation(Id locationId) {
    Id currentUserId = UserInfo.getUserId();
    User_Location__c userLocation = new User_Location__c(User__c = currentUserId, Branch__c = locationId, ProfileBranche__c = locationId); 
    List<User_Location__c> userLocations = new List<User_Location__c>{userLocation};
    insertRecords(userLocations, true);
    return userLocations;
  }

  private static List<sObject> insertRecords(
    List<sObject> records,
    boolean insertRecords
  ) {
    if (insertRecords) {
      String objApiName;
      if (records.size() > 0) {
        objApiName = String.valueOf(records[0].getSObjectType());
      }
      if (objApiName != 'Campaign') {
        SObjectAccessDecision decision = Security.stripInaccessible(
          AccessType.CREATABLE,
          records
        );
        List<sObject> tempRecords = decision.getRecords();
        System.debug('tempRecords = ' + tempRecords);
        insert tempRecords; //NOPMD
        for (Integer i = 0; i < tempRecords.size(); i++) {
          records.get(i).Id = tempRecords.get(i).Id;
        }
      } else {
        insert records;
      }
    }
    return records;
  }

}