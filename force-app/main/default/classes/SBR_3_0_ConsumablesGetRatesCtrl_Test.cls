/*********************************************************************************************************************
* Apex Class: SBR_3_0_ConsumablesGetRatesCtrl_Test
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Test class for SBR_3_0_ConsumablesGetRatesController

---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Revathi          	  2023-15-12            Initial version
*********************************************************************************************************************/
@isTest
public with sharing class SBR_3_0_ConsumablesGetRatesCtrl_Test {
  @TestSetup
  static void makeData() {
    Product_Hierarchy__c prdHierachy = new Product_Hierarchy__c(
      Name = 'Test Hierarchy',
      Product_Hierarchy_Code__c = 'Test_HR_Code',
      RecordTypeId = SBR_3_0_Constants.PRODUCT_HIERARCHY_PRODUCT_SUB_CATEGORY_RT_ID
    );
    insert prdHierachy;
    User u = new User(id = userinfo.getuserId());
    u.Department = '1';
    u.CompanyName = '1111';
    update u;

    Credential__c cred = SBR_3_0_TestDataFactory.createCredentials(1, false)[0];
    cred.Name = 'Mule_Token_Endpoint';
    cred.Key_Id__c = 'keyid';
    cred.Secret__c = 'credSecret';
    insert cred;

    RecordType skuRecordType = [
      SELECT Id, Name
      FROM RecordType
      WHERE SobjectType = 'Product2' AND Name = 'SKU'
    ];
    List<Product2> products = SBR_3_0_TestDataFactory.createProducts(3, false);
    for (Integer i = 0; i < products.size(); i++) {
      Integer j = i + 1;
      products[i].Name = 'Test Product';
      products[i].Sell_Price__c = 10;
      products[i].Product_SKU__c = j + '234567';
      products[i].Company_Code__c = '01';
      products[i].Product_Hierarchy__c = prdHierachy.Id;
      products[i].RecordTypeId = skuRecordType.Id;
    }
    products[1].Name = 'Test Optional SKU';
    products[2].Name = 'Test Without Product SKU';
    products[2].Product_SKU__c = null;
    insert products;
  }
  @istest
  static void TestgetProductRates() {
    List<Product2> products = [
      SELECT Id, Name
      FROM Product2
      WHERE Name = 'Test Product'
    ];
    SBR_3_0_ConsumablesGetRatesController.GetProductRatesWrapper wrap = new SBR_3_0_ConsumablesGetRatesController.GetProductRatesWrapper(
      '1111',
      new List<string>{ products[0].Id },
      new List<SBR_3_0_ConsumablesGetRatesController.Consumables_API_Request_Body_Product_V2>{
        new SBR_3_0_ConsumablesGetRatesController.Consumables_API_Request_Body_Product_V2(
          '12345',
          '12345',
          2,
          0.0
        )
      }
    );
    system.debug('wrap::' + wrap);
    Test.setMock(HttpCalloutMock.class, new SBR_3_0_ConsumablesCalloutMock());
    Test.startTest();
    string response = SBR_3_0_ConsumablesGetRatesController.getConsumableProductRates(
      wrap
    );
    Test.StopTest();
    system.assertNotEquals(string.isBlank(response), true);
  }
  public class SBR_3_0_ConsumablesCalloutMock implements HttpCalloutMock {
    public HTTPResponse respond(HTTPRequest req) {
      // Create a fake response
      HttpResponse res = new HttpResponse();
      res.setHeader('Content-Type', SBR_3_0_Constants.APP_JSON);
      if (req.getEndpoint().endsWithIgnoreCase('token')) {
        res.setBody('{"access_token":"test"}');
      } else {
        res.setBody(
          '{ "data": { "errorCode": "0000", "errorDesc": "Success", "company": "01", "customer": "4", "jobsite": "CO MEDIMMUNE BOULDER", "location": "0720","suggestedItems": [{"consumables": [{"specGroups": [{"products": [{"stockClass": "TEST","productNumber": "123456789"}]}]}]}], "items": [ { "catId": "123", "classId": "4567", "productId": "1234567", "rateFlag": "B", "rateFlagDescription": "Book Rates", "notToExceed": "", "notToExceedDescription": "No override needed for any change.", "rppPercentage": ".000", "needPassword": "FALSE", "showAllRates": "FALSE", "suggestMinimalHours": ".00", "isConsumerCatClass": "FALSE", "isSerialized": "FALSE", "customerDiscountPercentageDaily": ".00", "customerDiscountPercentageWeekly": ".00", "customerDiscountPercentageMonthly": ".00", "customerMonthly": null, "rates": { "suggestedRates": { "minimum": ".00", "daily": ".00", "weekly": ".00", "monthly": ".00" }, "bookRates": { "minimum": ".00", "daily": ".00", "weekly": ".00", "monthly": ".00" } } } ] } }'
        );
      }
      res.setStatusCode(200);
      return res;
    }
  }
}