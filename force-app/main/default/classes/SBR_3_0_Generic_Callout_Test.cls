@isTest
public with sharing class SBR_3_0_Generic_Callout_Test implements HttpCalloutMock {
  @TestSetup
  static void makeData() {
    Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
    cred.Name = 'Mule_Token_Endpoint';
    cred.Key_Id__c = 'testKey123';
    cred.Secret__c = 'secret';
    insert cred;

    Credential__c cred1 = SBR_3_0_TestDataFactory.createCredentials(
      1,
      false
    )[0];
    cred1.Name = 'AVS Check';
    cred1.Key_Id__c = 'testKey123';
    cred1.Secret__c = 'secret';
    insert cred1;
  }

  public HTTPResponse respond(HTTPRequest req) {
    HttpResponse res = new HttpResponse();
    res.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
    if (req.getEndpoint().endsWithIgnoreCase('token')) {
      res.setBody('{"access_token":"test"}');
    } else {
      res.setBody(
        '{ "data": { "errorCode": "0000", "errorDesc": "Success", "company": "01", "customer": "4", "jobsite": "CO MEDIMMUNE BOULDER", "location": "0720", "items": [ { "catId": "123", "classId": "4567", "productId": "1234567", "rateFlag": "B", "rateFlagDescription": "Book Rates", "notToExceed": "", "notToExceedDescription": "No override needed for any change.", "rppPercentage": ".000", "needPassword": "FALSE", "showAllRates": "FALSE", "suggestMinimalHours": ".00", "isConsumerCatClass": "FALSE", "isSerialized": "FALSE", "customerDiscountPercentageDaily": ".00", "customerDiscountPercentageWeekly": ".00", "customerDiscountPercentageMonthly": ".00", "customerMonthly": null, "rates": { "suggestedRates": { "minimum": ".00", "daily": ".00", "weekly": ".00", "monthly": ".00" }, "bookRates": { "minimum": ".00", "daily": ".00", "weekly": ".00", "monthly": ".00" } } } ] } }'
      );
    }
    res.setStatusCode(200);
    return res;
  }

  @isTest
  static void testCallEndPoint() {
    SBR_3_0_Generic_Callout.PaymentMethod = 'Amex';
    String ratesRequestJson = '{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }';

    Test.setMock(HttpCalloutMock.class, new SBR_3_0_Generic_Callout_Test());
    String result = '';
    Test.startTest();
    result = SBR_3_0_Generic_Callout.callEndpoint(
      ratesRequestJson,
      'Rates_API',
      '1'
    );
    System.assertNotEquals(' ', result);
    Test.stopTest();
  }

  @isTest
  static void testCallEndPoint1() {
    SBR_3_0_Generic_Callout.PaymentMethod = 'Amex';
    String ratesRequestJson = '{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }';

    Test.setMock(HttpCalloutMock.class, new SBR_3_0_Generic_Callout_Test());
    String result = '';
    Test.startTest();
    HttpResponse resp = new HttpResponse();
    resp = SBR_3_0_Generic_Callout.callEndpoint(ratesRequestJson, 'Rates_API');
    System.assertNotEquals(null, resp);
    List<String> pathParams;
    SBR_3_0_Generic_Callout.setURLParams(pathParams);
    Map<String, String> headers;
    SBR_3_0_Generic_Callout.setHeaders(headers);
    Test.stopTest();
  }
  @isTest
  static void testCallEndPointNotJWTEnabled() {
    String ratesRequestJson = '{ }';

    Test.setMock(HttpCalloutMock.class, new SBR_3_0_Generic_Callout_Test());
    String result = '';
    Test.startTest();
    SBR_3_0_HttpCallout call = new SBR_3_0_HttpCallout();
    call.apiMap.get('AVS_Check').Is_JWT_Enabled__c = false;
    call.apiMap.get('AVS_Check').Credential_Name__c = 'AVS Check';
    result = SBR_3_0_Generic_Callout.callEndpoint(
      ratesRequestJson,
      'AVS_Check',
      '1'
    );
    System.assertNotEquals(' ', result);
    Test.stopTest();
  }
    @isTest
    static void testCallEndpointWithJWT() {
        SBR_3_0_Generic_Callout.PaymentMethod = 'Amex';
        String ratesRequestJson = '{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }';

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Generic_Callout_Test());
        Test.startTest();
        HttpResponse resp = SBR_3_0_Generic_Callout.callEndpoint(ratesRequestJson, 'Rates_API');
        Test.stopTest();

        System.assertNotEquals(null, resp);
        System.assertEquals(200, resp.getStatusCode());
    }
    
     @isTest
    static void testCallEndpointEod() {
        String metadataApiName = 'Rates_API';
        String companyId = '1';
        String pc = '720';

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Generic_Callout_Test());
        Test.startTest();
        String result = SBR_3_0_Generic_Callout.callEndpointEod(metadataApiName, companyId, pc);
        Test.stopTest();

        System.assertNotEquals('', result);
    }

     @isTest
    static void testSetURLParamsAndHeaders() {
        List<String> pathParams = new List<String>{'param1', 'param2'};
        Map<String, String> headers = new Map<String, String>{'header1' => 'value1', 'header2' => 'value2'};

        SBR_3_0_Generic_Callout.setURLParams(pathParams);
        SBR_3_0_Generic_Callout.setHeaders(headers);

    }
      @isTest
    static void testCallEndpointWithCompanyId() {
        SBR_3_0_Generic_Callout.PaymentMethod = 'Amex';
        String ratesRequestJson = '{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }';

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Generic_Callout_Test());
        Test.startTest();
        String result = SBR_3_0_Generic_Callout.callEndpoint(ratesRequestJson, 'Rates_API', '1');
        Test.stopTest();

        System.assertNotEquals('', result);
    }

    @isTest
    static void testCallEndpointWithoutCompanyId() {
        SBR_3_0_Generic_Callout.PaymentMethod = 'Visa';
        String ratesRequestJson = '{ "pc": 720, "accountNumber": 4, "jobsiteName": "CO MEDIMMUNE BOULDER", "products": [ { "productId": "1234567" } ] }';

        Test.setMock(HttpCalloutMock.class, new SBR_3_0_Generic_Callout_Test());
        Test.startTest();
        String result = SBR_3_0_Generic_Callout.callEndpoint(ratesRequestJson, 'Rates_API', '');
        Test.stopTest();

        System.assertNotEquals('', result);
    }
}