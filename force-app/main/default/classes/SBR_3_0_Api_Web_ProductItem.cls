/**
 * @description       : 
 * @author            : Bill Convis - ServiceMax
 * @group             : 
 * @last modified on  : 08-17-2022
 * @last modified by  : Bill Convis - ServiceMax
**/
@RestResource(urlMapping='/ProductItem/ApiCreate/v1/*')
global with sharing class SBR_3_0_Api_Web_ProductItem {
    @HttpPost
    global static String createProductItem(){
        String returnVal = '';
        String strExternalId = '';
        ProductItemEvents piWrapper = (ProductItemEvents)JSON.deserialize(RestContext.request.requestBody.toString(), ProductItemEvents.class);
        //Get all of the Data
        for (PdtItemData piData : piWrapper.ProductItemData) {
            strExternalId = piData.companyCode + '-';
        }
        return returnVal;
    }
	public class ProductItemEvents {
		public String eventOrigin {get;set;} 
		public String eventType {get;set;} 
		public Integer uid {get;set;} 
		public String eventTimestamp {get;set;} 
		public String user {get;set;} 
		public String systemName {get;set;} 
		public List<PdtItemData> ProductItemData {get;set;} 
    }
    public class RelationalFields {
		public String unitOfMeasure {get;set;} 
    }

    public class PdtItemData {
		public String companyCode {get;set;} 
		public String branchLocNumber {get;set;} 
		public String category {get;set;} 
		public String class_Z {get;set;} // in json: class
		public String region {get;set;} 
		public String numberOfRentalUnits {get;set;} 
		public String qtyOnRent {get;set;} 
		public String qtyInTransit {get;set;} 
		public String qtyInOutsideShop {get;set;} 
		public String qtyMissing {get;set;} 
		public String qtyAvailable {get;set;} 
		public String qtyReserved {get;set;} 
		public String qtyWaitListd {get;set;} 
		public String qtyDueBack {get;set;} 
		public String qtyOnSchdldPickUp {get;set;} 
		public String qtyOnRentalPurchase {get;set;} 
		public String numberOfNewUnits {get;set;} 
		public String numberOfConsignedUnits {get;set;} 
		public String qtyInInsideShop {get;set;} 
		public String qtyTransferedOut {get;set;} 
		public String qtyReturned {get;set;} 
		public String qtyMinimum {get;set;} 
		public String cycleCode {get;set;} 
		public String lastDateCycleCounted {get;set;} 
		public String allowToGoNegative {get;set;} 
		public String qtyOnTruck {get;set;} 
		public Double bulkRepairExpenseMtd {get;set;} 
		public Double bulkRepairExpenseYtd {get;set;} 
		public Double bulkRepairExpenseLtd {get;set;} 
		public Double depreciationRatePercentTypeP {get;set;} 
		public String userDefnGLType {get;set;} 
		public String depreciationMethod {get;set;} 
		public String depreciationLifeInMonths {get;set;} 
		public Double salvageValuePercent {get;set;} 
		public String taxDepreciationMethod {get;set;} 
		public String taxDepreciationLifeInMonths {get;set;} 
		public Double taxSalvageValuePercent {get;set;} 
		public String amtDepreciationMethod {get;set;} 
		public String amtDepreciationLifeInMonths {get;set;} 
		public Double amtSalvageValuePercent {get;set;} 
		public String taxDepreciationMethod4 {get;set;} 
		public String taxDepreciationLifeInMonths4 {get;set;} 
		public Double taxSalvageValuePercent4 {get;set;} 
		public String taxDepreciationMethod5 {get;set;} 
		public String taxDepreciationLifeInMonths5 {get;set;} 
		public Double taxSalvageValuePercent5 {get;set;} 
		public RelationalFields relationalFields {get;set;} 
    }
}