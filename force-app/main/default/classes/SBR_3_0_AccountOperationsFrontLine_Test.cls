/**
 * @description       :
 * @author            : ChangeMeIn@UserSettingsUnder.SFDoc
 * @group             :
 * @last modified on  : 12-21-2023
 * @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
 **/
@isTest
public class SBR_3_0_AccountOperationsFrontLine_Test implements HttpCalloutMock {
  public HTTPResponse respond(HTTPRequest req) {
    // Create a fake response
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
    if (req.getEndpoint().endsWithIgnoreCase('token')) {
      res.setBody('{"access_token":"test"}');
    } else {
      res.setBody('{"data":{"rmAccountNumber":1234}}');
    }
    res.setStatusCode(200);
    return res;
  }
  /*
    public HTTPResponse respond(HTTPRequest req) {
        HTTPResponse res = new HTTPResponse();
        res.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
        res.setBody('{"data":{"rmAccountNumber":1234}}');
        res.setStatusCode(200);

        return res;
    }
    */
  @TestSetup
  static void makeData() {
    Profile p = [SELECT Id FROM Profile WHERE Name = 'System Administrator'];

    String uName = 'admin' + DateTime.now().getTime() + '@SBRtestorg.com';
    User admin = new User(
      Alias = 'admin',
      Email = 'adminuser1@testorg.com',
      RepId__c = '1092345',
      EmailEncodingKey = 'UTF-8',
      LastName = 'Admin1',
      LanguageLocaleKey = 'en_US',
      LocaleSidKey = 'en_US',
      ProfileId = p.Id,
      TimeZoneSidKey = 'America/Los_Angeles',
      UserName = uName
    );
    insert admin;

    Schema.Location loc = new Schema.Location();
    loc.recordTypeId = SBR_3_0_Constants.LOCATION_BRANCH_RT_ID;
    loc.Name = '1799 Innovation Point';
    loc.Street_Address__c = '1799 Innovation Point';
    loc.State__c = 'SC';
    loc.Zip_Code__c = '29715';
    loc.Branch_Location_Number__c = '0411';
    insert loc;

    User_Location__c ul = new User_Location__c(
      User__c = admin.Id,
      Branch__c = loc.Id
    );
    insert ul;
  }
  @isTest
  static void testCreateLocationAndJobSite() {
    User admin = [
      SELECT Id
      FROM User
      WHERE Email = 'adminuser1@testorg.com' AND LastName = 'Admin1'
      LIMIT 1
    ];
    System.runAs(admin) {
      Credential__c credentials = SBR_3_0_TestDataFactory.createCredentials(
        1,
        false
      )[0];
      credentials.Name = 'Mule_Token_Endpoint';
      credentials.Key_Id__c = 'testKey123';
      credentials.Secret__c = 'secret';
      insert credentials;
      Test.setMock(
        HttpCalloutMock.class,
        new SBR_3_0_AccountOperationsFrontLine_Test()
      );

      Test.startTest();
      List<Account> accs = SBR_3_0_TestDataFactory.createAccounts(
        1,
        false,
        'Non_Credit'
      );
      accs[0].Name = 'Kumar, Neeraj';
      accs[0].Driver_s_License_State__c = 'SC';
      accs[0].BillingState = 'SC';
      accs[0].BillingStreet = '1799 Innovation Point';
      accs[0].BillingCity = 'fortmill';
      accs[0].BillingCountry = 'US';
      accs[0].BillingPostalCode = '29715';
      accs[0].Drivers_License__c = '1233';
      accs[0].ShippingState = 'SC';
      accs[0].ShippingStreet = '1799 Innovation Point';
      accs[0].ShippingCity = 'fortmill';
      accs[0].ShippingCountryCode = 'US';
      accs[0].ShippingPostalCode = '29715';
      accs[0].Company_code__c = '01';
      insert accs;

      System.AssertNotEquals(
        [SELECT id FROM AssociatedLocation WHERE ParentRecordId = :accs[0].Id],
        null,
        'Job Site Created'
      );

      accs[0].BillingState = 'CA';
      accs[0].BillingStreet = '1544 Broadway';
      accs[0].BillingCity = 'Oakland';
      accs[0].BillingCountry = 'US';
      accs[0].BillingPostalCode = '94612';
      update accs;
      AssociatedLocation js1 = [
        SELECT id, City__c
        FROM AssociatedLocation
        WHERE ParentRecordId = :accs[0].Id
      ];
      System.assertEquals(accs[0].BillingCity, js1.City__c);
      Test.stopTest();
    }
  }
}