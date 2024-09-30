/*********************************************************************************************************************
* Apex Class: SBR_3_0_ConsumablesGetRatesController
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* Controller class for getting Rates for Sales Items in sbr_3_0_consumabaleSpotlightPanelCmp LWC

---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Revathi          	  2023-14-12            Initial version
*********************************************************************************************************************/
public without sharing class SBR_3_0_ConsumablesGetRatesController {
  //Added as part of FRONT-8623
  private static final String APINAME_V2 = 'Rates_API_V2';
  @AuraEnabled(cacheable=true)
  public static String getConsumableProductRates(
    GetProductRatesWrapper prwrapper
  ) {
    System.debug('===prwrapper===' + prwrapper);
    User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
    Integer pc = Integer.valueOf(loggedInUser.Department);
    String companyId = '1'; //companyId here is the company code to indicate whether it's US(1) or Canada(2)
    if (loggedInUser.CompanyName != null && loggedInUser.CompanyName != '') {
      companyId = String.valueOf(Integer.valueOf(loggedInUser.CompanyName));
    }
    prwrapper.pc = pc;
    Rates_API_Request_Body_V2 req = new Rates_API_Request_Body_V2(prwrapper);
      System.debug('===ratesrequest===' + JSON.serializePretty(req, true));
    String response = getRates_V2(JSON.serializePretty(req, true), companyId);
    System.debug('===response===' + response);
    return response;
  }
  //wrapper class for req for getConsumableProductRates
  public class GetProductRatesWrapper {
    @AuraEnabled
    public Integer pc { get; set; }
    @AuraEnabled
    public String customerNumber { get; set; }
    @AuraEnabled
    public List<String> products { get; set; }
    @AuraEnabled
    public List<Consumables_API_Request_Body_Product_V2> items { get; set; }

    public GetProductRatesWrapper() {
    }
    public GetProductRatesWrapper(
      String customerNumber,
      List<String> products
    ) {
      this.customerNumber = customerNumber;
      this.products = products;
    }
    public GetProductRatesWrapper(
      String customerNumber,
      List<String> products,
      List<Consumables_API_Request_Body_Product_V2> items
    ) {
      this.customerNumber = customerNumber;
      this.products = products;
      this.items = items;
    }
  }
  //wrapper class for requestBody for Rates API
  public class Rates_API_Request_Body_V2 {
    public String accountNumber { get; set; }
    public String jobsite { get; set; }
    public List<Rates_API_Request_Body_Product_V2> products { get; set; }
    public Consumables_API_Request_Body_V2 salesItems { get; set; }

    public Rates_API_Request_Body_V2(GetProductRatesWrapper prwrapper) {
      setProducts(prwrapper);
      setAccountNumber(prwrapper.customerNumber);
      setSalesItems(prwrapper);
    }
    public void setProducts(GetProductRatesWrapper prwrapper) {
      if (prwrapper.products != null && !prwrapper.products.isEmpty()) {
        List<Rates_API_Request_Body_Product_V2> pl = new List<Rates_API_Request_Body_Product_V2>();
        for (String productId : prwrapper.products) {
          Rates_API_Request_Body_Product_V2 requestedProduct = new Rates_API_Request_Body_Product_V2(
            productId
          );
          requestedProduct.pc = prwrapper.pc;
          pl.add(requestedProduct);
        }
        this.products = pl;
      }
    }
    public void setAccountNumber(String accountNumber) {
      if (String.isNotEmpty(accountNumber)) {
        if (accountNumber.contains('-')) {
          accountNumber = accountNumber.subStringAfter('-');
        }
        this.accountNumber = accountNumber;
      }
    }
    public void setSalesItems(GetProductRatesWrapper prwrapper) {
      if (prwrapper.items != null && prwrapper.items.size() > 0) {
        this.salesItems = new Consumables_API_Request_Body_V2(
          prwrapper.items,
          prwrapper.pc
        );
      }
    }
  }
  //wrapper class for products in Rates API request body
  public class Rates_API_Request_Body_Product_V2 {
    public String productId { get; set; }
    public Integer pc { get; set; }
    public Rates_API_Request_Body_Product_V2(String productId) {
      this.productId = productId;
    }
  }
  public class Consumables_API_Request_Body_V2 {
    public List<Consumables_API_Request_Body_Product_V2> items { get; set; }
    public String pc { get; set; }
    public Consumables_API_Request_Body_V2(
      List<Consumables_API_Request_Body_Product_V2> items,
      Integer pc
    ) {
      this.items = items;
      this.pc = String.valueOf(pc);
    }
  }
  public class Consumables_API_Request_Body_Product_V2 {
    @AuraEnabled
    public String itemNumber { get; set; }
    @AuraEnabled
    public String stockClass { get; set; }
    @AuraEnabled
    public Integer quantity { get; set; }
    @AuraEnabled
    public Decimal cost { get; set; }
    public Consumables_API_Request_Body_Product_V2() {
    }
    public Consumables_API_Request_Body_Product_V2(
      String itemNumber,
      String stockClass,
      Integer quantity,
      Decimal cost
    ) {
      this.itemNumber = itemNumber;
      this.stockClass = stockClass;
      this.quantity = quantity;
      this.cost = cost;
    }
  }
  //Added as part of FRONT-8623
  @AuraEnabled
  public static String getRates_V2(String ratesRequestJson, String companyId) {
    String returnPayload = '';
    returnPayload = SBR_3_0_Generic_Callout.callEndpoint(
      ratesRequestJson,
      APINAME_V2,
      companyId
    );
    return returnPayload;
  }

  @AuraEnabled(cacheable=true)
  public static String getContractProductRates(
    GetProductRatesWrapper prwrapper
  ) {
    System.debug('===prwrapper===' + prwrapper);
    User loggedInUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
    Integer userProfileBranch = Integer.ValueOf(sbr_3_0_SpotlightPanelCmpController.getProfileBranchDetailsForContracts().Branch_Location_Number__c);
    String companyId = '1'; //companyId here is the company code to indicate whether it's US(1) or Canada(2)
    if (loggedInUser.CompanyName != null && loggedInUser.CompanyName != '') {
      companyId = String.valueOf(Integer.valueOf(loggedInUser.CompanyName));
    }
    prwrapper.pc = userProfileBranch;
    Rates_API_Request_Body_V2 req = new Rates_API_Request_Body_V2(prwrapper);
      System.debug('===ratesrequest===' + JSON.serializePretty(req, true));
    String response = getRates_V2(JSON.serializePretty(req, true), companyId);
    System.debug('===response===' + response);
    return response;
  }

}