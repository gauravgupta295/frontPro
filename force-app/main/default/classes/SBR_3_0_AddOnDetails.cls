/**
 * @description       : wrapper class for product details
 * @author            : Pavan Konduru
 * @group             :
 * @last modified on  : 03-07-2024
 * @last modified by  : Pavan Konduru
 **/
@SuppressWarnings('PMD')
public class SBR_3_0_AddOnDetails {
  public String id;
  public String name;
  public String catClass;
  public String productType;
  public String itemNumber;
  public String stockClass;
  public String category;
  public String subcategory;
  public String ratesDaily;
  public String ratesWeekly;
  public String ratesMonthly;
  public String minRate;
  public String availabilityA;
  public String availabilityU;
  public String availabilityR;
  public Decimal sellPrice;
  public Decimal availQuantity;
  public String addonType;
  public Boolean isRequired;
  public String rateFlag;
  public String notToExceed;
  public Decimal minQuantity;
  public Boolean inventoriedItem;
  public Boolean miscellaneousChargeItem;
  public String typeOfMiscChargeItem;
  public Boolean userSelectableForQuote;
  public String isKit;
  public Boolean isChangeable;
  public String rateBranch;
  public String parentSKU;
  public String featureName;
  public Boolean isProfileBranchUsed;

  /**
  * @description 
  * @author Pavan Konduru | 03-07-2024 
  * @param ao 
  **/
  public SBR_3_0_AddOnDetails(SBQQ__ProductOption__c ao) {
    this.id = ao.SBQQ__OptionalSKU__r.Id;
    this.name = ao.SBQQ__OptionalSKU__r.name;
    this.productType = ao.SBQQ__OptionalSKU__r.Product_Type__c;
    this.itemNumber = ao.SBQQ__OptionalSKU__r.Item_Number__c;
    this.stockClass = ao.SBQQ__OptionalSKU__r.Stock_class__c;
    this.catClass = ao.SBQQ__OptionalSKU__r.Product_SKU__c;
    this.sellPrice = ao.SBQQ__OptionalSKU__r.Sell_Price__c;
    this.isRequired = ao.SBQQ__Required__c;
    this.availQuantity = ao.SBQQ__Quantity__c != null
      ? ao.SBQQ__Quantity__c
      : 0;
    this.availabilityA = 'n/a';
    this.availabilityU = 'n/a';
    this.availabilityR = 'n/a';
    this.ratesDaily = 'n/a';
    this.ratesWeekly = 'n/a';
    this.ratesMonthly = 'n/a';
    // SAL-26036
    this.inventoriedItem = ao.SBQQ__OptionalSKU__r.Inventoried_Item__c;
    this.miscellaneousChargeItem = ao.SBQQ__OptionalSKU__r.Miscellaneous_Charge_Item__c;
    this.typeOfMiscChargeItem = ao.SBQQ__OptionalSKU__r.Type_of_Misc_Charge_Item__c;
    this.userSelectableForQuote = ao.SBQQ__OptionalSKU__r.User_Selectable_for_Quote__c;
    this.parentSKU = ao.SBQQ__ConfiguredSKU__r.Product_SKU__c;
    this.featureName = ao.SBQQ__Feature__r.Name;
  }
  
  /**
  * @description 
  * @author Pavan Konduru | 03-07-2024 
  * @param ao 
  **/
  public SBR_3_0_AddOnDetails(Product2 ao) {
    this.id = ao.id;
    this.name = ao.name;
    this.productType = ao.Product_Type__c;
    this.itemNumber = ao.Item_Number__c;
    this.stockClass = ao.Stock_class__c;
    this.category = ao.Product_Category__c;
    this.subcategory = ao.Product_Sub_Category__c;
    this.catClass = ao.Product_SKU__c;
    this.sellPrice = ao.Sell_Price__c;
    this.availabilityA = 'n/a';
    this.availQuantity = 0;
    this.availabilityU = 'n/a';
    this.availabilityR = 'n/a';
    this.ratesDaily = 'n/a';
    this.ratesWeekly = 'n/a';
    this.ratesMonthly = 'n/a';
    // SAL-26036
    this.inventoriedItem = ao.Inventoried_Item__c;
    this.miscellaneousChargeItem = ao.Miscellaneous_Charge_Item__c;
    this.typeOfMiscChargeItem = ao.Type_of_Misc_Charge_Item__c != null
      ? ao.Type_of_Misc_Charge_Item__c
      : '';
    this.userSelectableForQuote = ao.User_Selectable_for_Quote__c;
    this.isKit = ao.Is_Kit__c;
    this.isChangeable = ao.Changeable__c;
  }
}