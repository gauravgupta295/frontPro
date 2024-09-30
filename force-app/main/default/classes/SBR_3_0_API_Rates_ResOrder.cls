/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Rates_ResOrder
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Fetch Product Rates from Wayne ERP (RentalMan) using Mulesoft
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Shreenivas Adapur       2023-01-25          Initial version
*********************************************************************************************************************/
public without sharing class SBR_3_0_API_Rates_ResOrder {

    @AuraEnabled
    public static String refreshResOrderRates(Id orderId){
        String returnVal = '';
        try {
            returnVal = updateResOrderRate(orderId);
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage() + '\n' + e.getStackTraceString());
        }
        return returnVal;
    }

    public static String updateResOrderRate(Id orderId){
        String returnVal = '';
        SBR_3_0_API_RatesRequestWrapper reqWrapper = new SBR_3_0_API_RatesRequestWrapper();
        Map<Id, Order> oOrder = SBR_3_0_OrderDA.getOrders(new set<Id> {orderId});
        System.debug('\n @@oOrder->' + oOrder);
        String companyCode = '';
        if(!oOrder.isEmpty()){
            Order orderRec = oOrder.values()[0];
            companyCode = orderRec.Company_Code__c != null ? orderRec.Company_Code__c : orderRec?.Account?.Company_Code__c;
            if(companyCode.length() == 1 && !companyCode.startsWith('0')) { companyCode = '0' + companyCode; }
            // Separate Cat-Class Product types
            Map<String, OrderItem> catClassProducts = new Map<String, OrderItem>();
 			Map<String,List<OrderItem>> catClassProductsListMap = new Map<String,List<OrderItem>>();
			Map<String,List<OrderItem>> suggestedProductsListMap = new Map<String,List<OrderItem>>();
            Map<String, SBR_3_0_API_RatesResponseWrapper.Items> catClassResponseProducts = new Map<String, SBR_3_0_API_RatesResponseWrapper.Items>();
            Map<String, OrderItem> suggestedProducts = new Map<String, OrderItem>();
            Map<String, SBR_3_0_API_ConsumablesResponse.Products> suggestedResponseProducts = new Map<String, SBR_3_0_API_ConsumablesResponse.Products>();
            List<OrderItem> lineItemList = new List<OrderItem>();
			List<OrderItem> allOrderLines = new List<OrderItem>();
            Map<String, String> mapSKUandRateBranch = new  Map<String, String>();
            for(OrderItem orderLineItem : orderRec.OrderItems){
                if(orderLineItem.Product2.Product_Type__c == SBR_3_0_Constants.CAT_CLASS){
                    catClassProducts.put(orderLineItem.Product2.Product_SKU__c, orderLineItem);
                      if(catClassProductsListMap.containsKey(orderLineItem.Product2.Product_SKU__c))
                    {
                         lineItemList = new List<OrderItem>();
                        lineItemList = catClassProductsListMap.get(orderLineItem.Product2.Product_SKU__c);
                        lineItemList.add(orderLineItem);
                        catClassProductsListMap.put(orderLineItem.Product2.Product_SKU__c, lineItemList);
                    }
                    else{
                            lineItemList = new List<OrderItem>();
                            lineItemList.add(orderLineItem);
                            catClassProductsListMap.put(orderLineItem.Product2.Product_SKU__c, lineItemList);
                            mapSKUandRateBranch.put(orderLineItem.Product2.Product_SKU__c ,orderLineItem.Rates_Branch__c);

                    }
                } else if((orderLineItem.Product2.Product_Type__c == SBR_3_0_Constants.PARTS || orderLineItem.Product2.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || orderLineItem.Product2.Product_Type__c == 'MISC Charge Items')) {
                    suggestedProducts.put((orderLineItem.Product2.Stock_Class__c + orderLineItem.Product2.Item_Number__c), orderLineItem);
                     if(suggestedProductsListMap.containsKey(orderLineItem.Product2.Stock_Class__c + orderLineItem.Product2.Item_Number__c))
                    {
                         lineItemList = new List<OrderItem>();
                        lineItemList = suggestedProductsListMap.get(orderLineItem.Product2.Stock_Class__c + orderLineItem.Product2.Item_Number__c);
                        lineItemList.add(orderLineItem);
                        suggestedProductsListMap.put(orderLineItem.Product2.Stock_Class__c + orderLineItem.Product2.Item_Number__c, lineItemList);
                    }
                    else{
                            lineItemList = new List<OrderItem>();
                            lineItemList.add(orderLineItem);
                            suggestedProductsListMap.put(orderLineItem.Product2.Stock_Class__c + orderLineItem.Product2.Item_Number__c, lineItemList);

                    }
                }
            }
            System.debug('\n @@suggested prods =' + suggestedProducts);

            // Call Rates API for Main Products
            if(!catClassProducts.isEmpty()) {
                SBR_3_0_API_RatesResponseWrapper respWrapper = SBR_3_0_API_Rates.getRatesFromRatesAPI(orderRec.Jobsite__r.Branch__r.Branch_Location_Number__c, 
                orderRec.Account.RM_Account_Number__c, 
                orderRec.Jobsite__r.JobsiteName__c, 
                orderRec.Account.Company_Code__c, mapSKUandRateBranch);

                for(SBR_3_0_API_RatesResponseWrapper.Items item: respWrapper.data.items){
                    catClassResponseProducts.put(item.productId, item);
                }
                 // Populate Rates for Cat-Class Products
                //integer i = 1;
                // Part for Rentables 

                for(String productSku: catClassProductsListMap.keySet() )
                {
                    for(OrderItem orderLine: catClassProductsListMap.get(productSku)){
                        
                            if(catClassResponseProducts.containsKey(orderLine.Product2.Product_SKU__c)){
    
                            orderLine.Min_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.minimum);
                            orderLine.Hourly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.minimum);
                            orderLine.Daily_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.daily);
                            orderLine.Weekly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.weekly);
                            orderLine.Monthly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.monthly);
                            
                            orderLine.Suggested_Minimum_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.minimum);
                            orderLine.Suggested_Hourly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.minimum);                        
                            orderLine.Suggested_Daily_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.daily);
                            orderLine.Suggested_Weekly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.weekly);
                            orderLine.Suggested_Monthly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(orderLine.Product2.Product_SKU__c).rates.suggestedRates.monthly);
                            allOrderLines.add(orderLine);
                        } else {
                            throw new SBR_3_0_API_Rates_Exception('Product Rates Not Found for: ' + orderLine.Product2.Product_SKU__c);
                        }
                    }
                }
				// for Consumables Parts and Merchandise  
                if(!suggestedProducts.isEmpty()) {
                // Call Consumables API for Suggested Products
                    SBR_3_0_API_ConsumablesResponse consResp = SBR_3_0_API_Rates.getRatesFromConsumablesAPI(orderRec.Jobsite__r.Branch__r.Branch_Location_Number__c, 
                    orderRec.Account.RM_Account_Number__c, 
                    orderRec.Jobsite__r.Job_Number__c, 
                    companyCode, catClassProducts.keySet());

                    for(SBR_3_0_API_ConsumablesResponse.SuggestedItems suggItem: consResp.data.suggestedItems){
                        for(SBR_3_0_API_ConsumablesResponse.Consumables consumble: suggItem.consumables){
                            for(SBR_3_0_API_ConsumablesResponse.SpecGroups specGrp: consumble.specGroups){
                                for(SBR_3_0_API_ConsumablesResponse.Products prd: specGrp.products){
                                    //String prdSku = companyCode + '-' + prd.stockClass + '-' + prd.productNumber;
                                    String prdSku =  prd.stockClass + prd.productNumber;
                                    suggestedResponseProducts.put(prdSku, prd);
                                }
                            }
                        }
                    }
                    System.debug('\n@@suggested prods response = ' + suggestedResponseProducts);
                
               
                    // Populate Rates for Suggested Products
                 
                    for(String itemNum : suggestedProductsListMap.keySet() )
                	{
                        for(OrderItem orderLine: suggestedProductsListMap.get(itemNum)){
                        System.debug('\n @@orderLine.Product2.Product_SKU__c= ' +  orderLine.Product2.Product_SKU__c);
                        System.debug('\n@@suggested prods response2 = ' + suggestedResponseProducts);
                        if(suggestedResponseProducts.containsKey(orderLine.Product2.Stock_Class__c + orderLine.Product2.Item_Number__c)){
                            orderLine.Selling_Price__c = Decimal.valueOf(suggestedResponseProducts.get((orderLine.Product2.Stock_Class__c + orderLine.Product2.Item_Number__c)).sellingPrice);
                            allOrderLines.add(orderLine);

                        } 
                        }}
                }

                
             
                if(!allOrderLines.isEmpty()){
                    System.debug('allOrderLines->'+allOrderLines);
                    update allOrderLines;
                }
            }
        }
        return returnVal;
    }

    public class SBR_3_0_API_Rates_Exception extends Exception{}
}