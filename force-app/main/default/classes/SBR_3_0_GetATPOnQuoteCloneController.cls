/**
* @description       :  Get ATP call when cloning Quote
* @author            : 
* @group             : 
* @last modified on  : 01-09-2024
* @last modified by  : ChangeMeIn@UserSettingsUnder.SFDoc
**/
public class SBR_3_0_GetATPOnQuoteCloneController {
    
    @InvocableMethod(label = 'get Quote Rates Branch From ATP Call')
    public static  List<cloneResponse> updateQuoteLineItemsWithRates(List<CloneRequest> cloneData){
        List<cloneResponse> returnVal = new List<cloneResponse>();
        try{
            
            List<Schema.Location> userProfileLocation = SBR_3_0_BranchDA.getLoggedInUserLocation();
            if(userProfileLocation.size() == 0) {
                cloneResponse cr = new cloneResponse();
                cr.isSuccess = false;
                returnVal.add(cr);
                return returnVal;
            }
            String objectName =  cloneData[0].objectName;
            SBQQ__Quote__c selectedQuote = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{cloneData[0].quoteId}).values()[0];
            Schema.Location locationRec = SBR_3_0_SpotlightPanelCmpController.getBranchChronosDetailsNew(selectedQuote.Id, objectName);
            
            
            if(cloneData[0].isAccountOrJobSiteChanged && locationRec.OMS_Sourcing_Enabled__c){
                String companyCode;
                companyCode = locationRec.Company_Code__c;
                SBR_3_0_WrapInventoryAtBranch.ATPRequest atpReqObj = new SBR_3_0_WrapInventoryAtBranch.ATPRequest();
                if (String.isBlank(companyCode)) {
                    User u = [SELECT CompanyName FROM User WHERE Id = :UserInfo.getUserId()];
                    companyCode = u.CompanyName;
                }
                
                API_ATP_Config__mdt atpFieldConfig = SBR_3_0_CustomMetadata_DA.getATPApiConfig('Prod_Inquiry');
                atpReqObj.orgId = companyCode;
                atpReqObj.cartId = SBR_3_0_Constants.SELLING_CHANNEL;
                atpReqObj.fulfillmentType = SBR_3_0_Constants.ATP_FULFILLMENTTYPE_DELIVERY;
                atpReqObj.sellingChannel = SBR_3_0_Constants.SELLING_CHANNEL;
                if(atpFieldConfig <> NULL){
                    atpReqObj.includeZeroATP = atpFieldConfig.Include_Zero_ATP__c;
                    atpReqObj.limitBranchByDistanceCount = Integer.valueOf(atpFieldConfig.Limit_Branch_By_Distance__c);
                }
                
                if (objectName == 'SBQQ__Quote__c'){
                    String formatted = selectedQuote.Start_Date__c.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
                    atpReqObj.requestedDeliveryDate = formatted;
                    // SAL-24258 - Start
                    if(selectedQuote.SBQQ__DeliveryMethod__c == 'Delivery' && selectedQuote.OMS_Sourcing_Enabled__c){
                        if(selectedQuote.Jobsite__r.Latitude_Longitude__Latitude__s <> NULL && 
                           selectedQuote.Jobsite__r.Latitude_Longitude__Longitude__s <> NULL){
                               atpReqObj.latitude = selectedQuote.Jobsite__r.Latitude_Longitude__Latitude__s;
                               atpReqObj.longitude = selectedQuote.Jobsite__r.Latitude_Longitude__Longitude__s;
                               atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_JOBSITE;
                               // SAL-25138
                               if(selectedQuote.Jobsite__r.Time_Zone_Id__c !=null){
                                    atpReqObj.timezoneId = selectedQuote.Jobsite__r.Time_Zone_Id__c;
                               }
                               else if(selectedQuote.Sourcing_Branch__r <> NULL && selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c != null){
                                    atpReqObj.timezoneId = selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c; 
                               }
                           }else if(selectedQuote.Sourcing_Branch__r <> NULL && 
                                    selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                                    selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                           {
                               atpReqObj.latitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                               atpReqObj.longitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                               atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                               // SAL-25138
                               atpReqObj.timezoneId = selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c;
                           } else if(selectedQuote.Branch__r <> NULL && 
                                     selectedQuote.Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                                     selectedQuote.Branch__r.Latitude_Longitude__Longitude__s <> NULL)
                           {
                               atpReqObj.latitude = selectedQuote.Branch__r.Latitude_Longitude__Latitude__s;
                               atpReqObj.longitude = selectedQuote.Branch__r.Latitude_Longitude__Longitude__s;
                               atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                               // SAL-25138
                               atpReqObj.timezoneId = selectedQuote.Branch__r.Time_Zone_Id__c;
                           }
                    } else if(selectedQuote.SBQQ__DeliveryMethod__c == 'Pickup'){
                        atpReqObj.fulfillmentType = SBR_3_0_Constants.FULFILLMENT_TYPE_CPU;
                        if(selectedQuote.Sourcing_Branch__r <> NULL && selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s <> NULL && 
                           selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s <> NULL){
                               
                               atpReqObj.latitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Latitude__s;
                               atpReqObj.longitude = selectedQuote.Sourcing_Branch__r.Latitude_Longitude__Longitude__s;
                               atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                               // SAL-25138
                               atpReqObj.timezoneId = selectedQuote.Sourcing_Branch__r.Time_Zone_Id__c;
                           }
                    } else {
                        Schema.Location userLocation = userProfileLocation[0];
                        Datetime myDateTime = Datetime.now();
                        formatted = myDateTime.formatGmt(SBR_3_0_Constants.INT_DATE_FORMAT); 
                        atpReqObj.requestedDeliveryDate = formatted;
                        if(userLocation.Latitude_Longitude__Latitude__s <> NULL && userLocation.Latitude_Longitude__longitude__s <> NULL){
                            atpReqObj.latitude = userLocation.Latitude_Longitude__Latitude__s;
                            atpReqObj.longitude = userLocation.Latitude_Longitude__longitude__s;
                            atpReqObj.locationType = SBR_3_0_Constants.LOCATIONTYPE_BRANCH;
                            atpReqObj.timezoneId = userLocation.Time_Zone_Id__c;
                        }
                    }
                    
                    List<SBR_3_0_WrapInventoryAtBranch.Products> products = new list<SBR_3_0_WrapInventoryAtBranch.Products>();
                    for(SBQQ__QuoteLine__c qitem : selectedQuote.SBQQ__LineItems__r){
                        if(qitem.SBQQ__Product__c != null && qitem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS){
                            SBR_3_0_WrapInventoryAtBranch.Products p = new SBR_3_0_WrapInventoryAtBranch.Products();
                            p.uom = 'EA';
                            p.productId = qitem.SBQQ__Product__r.Product_SKU__c;
                            products.add(p);
                        }
                    }
                    atpReqObj.products = products;
                    
                    Map<String, String> catClassBranchMap = new   Map<String, String>();
                    List<String> noAvailabilityByLocationsList = new List<String>();
                    
                    SBR_3_0_WrapInventoryAtBranch.ATPResponse response = SBR_3_0_API_FetchInventoryAtBranch.getInventoryAtBranch(atpReqObj,companyCode);
                    
                    if(response != null){
                        for(SBR_3_0_WrapInventoryAtBranch.AvailabilityByProducts res : response.availabilityByProducts){
                            if( res.availabilityByFulfillmentTypes.size() > 0 && res.availabilityByFulfillmentTypes[0].availabilityDetails.size() > 0 &&  res.availabilityByFulfillmentTypes[0].availabilityDetails[0].availabilityByLocations.size() > 0 ){
                                String ratesBranch = res.availabilityByFulfillmentTypes[0].availabilityDetails[0].availabilityByLocations[0].locationId;
                                ratesBranch = ratesBranch.split('-')[1];
                                catClassBranchMap.put(res.productId , ratesBranch);   
                            }
                            else if(res.productId != null){
                                noAvailabilityByLocationsList.add(res.productId);   
                            }
                        }
                    }
                    
                    if(!noAvailabilityByLocationsList.isEmpty()){
                        List<SBR_3_0_WrapInventoryAtBranch.Products> noAvailabilityByLocationproducts = new list<SBR_3_0_WrapInventoryAtBranch.Products>();
                        SBR_3_0_WrapInventoryAtBranch.Products  noAvailabilityByLocationproduct = new SBR_3_0_WrapInventoryAtBranch.Products();
                        noAvailabilityByLocationproduct.uom = 'EA';
                        noAvailabilityByLocationproduct.productId = noAvailabilityByLocationsList[0];
                        noAvailabilityByLocationproducts.add(noAvailabilityByLocationproduct);
                        atpReqObj.products = noAvailabilityByLocationproducts;
                        SBR_3_0_WrapInventoryAtBranch.ATPResponse noAvailabilityByLocationsresponse = SBR_3_0_API_FetchInventoryAtBranch.getInventoryAtBranch(atpReqObj,companyCode);
                        if(noAvailabilityByLocationsresponse != null){
                            if(noAvailabilityByLocationsresponse.lastResortBranch !=null){
                                String lastResortBranch = noAvailabilityByLocationsresponse.lastResortBranch;
                                lastResortBranch =lastResortBranch?.split('-').size() > 1  ?  lastResortBranch?.split('-')[1] : lastResortBranch?.split('-')[0];
                                for(string catClass : noAvailabilityByLocationsList){
                                    catClassBranchMap.put(catClass , lastResortBranch);   
                                }
                            }
                        }           
                    }  
                    
                    
                    for(SBQQ__QuoteLine__c qitem : selectedQuote.SBQQ__LineItems__r){
                        if(catClassBranchMap.get(qitem.SBQQ__Product__r.Product_SKU__c) !=null && qitem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS){
                            qitem.Rates_Branch__c =   catClassBranchMap.get(qitem.SBQQ__Product__r.Product_SKU__c);
                        }
                        else{
                            //use user branch if ATP fails
                            qitem.Rates_Branch__c =   userProfileLocation[0].Branch_Location_Number__c;
                        }
                    } 
                    
                    getQuoteRates(selectedQuote, selectedQuote.SBQQ__LineItems__r);
                    cloneResponse cr = new cloneResponse();
                    cr.isSuccess = true;
                    returnVal.add(cr);
                }
            }
            else{
                getQuoteRates(selectedQuote, selectedQuote.SBQQ__LineItems__r);
                cloneResponse cr = new cloneResponse();
                cr.isSuccess = true;
                returnVal.add(cr);
            } 
        }
        catch(Exception e){
            cloneResponse cr = new cloneResponse();
            cr.isSuccess = false;
            returnVal.add(cr);
        }
        return returnVal;
    }
    
    
    public static void getQuoteRates(SBQQ__Quote__c quoteRec, List<SBQQ__QuoteLine__c> quoteLineItems){
        
        SBR_3_0_API_RatesRequestWrapper reqWrapper = new SBR_3_0_API_RatesRequestWrapper();
        String companyCode = '';
        if(quoteRec!=null){
            companyCode = quoteRec.Company_Code__c != null ? quoteRec.Company_Code__c : quoteRec?.SBQQ__Account__r?.Company_Code__c;
            if(companyCode.length() == 1 && !companyCode.startsWith('0')) { companyCode = '0' + companyCode; }
            // Separate Cat-Class Product types
            Map<String, SBQQ__QuoteLine__c> catClassProducts = new Map<String, SBQQ__QuoteLine__c>();
            Map<String,List<SBQQ__QuoteLine__c>> catClassProductsListMap = new Map<String,List<SBQQ__QuoteLine__c>>();
            Map<String,List<SBQQ__QuoteLine__c>> suggestedProductsListMap = new Map<String,List<SBQQ__QuoteLine__c>>();
            Map<String, SBR_3_0_API_RatesResponseWrapper.Items> catClassResponseProducts = new Map<String, SBR_3_0_API_RatesResponseWrapper.Items>();
            Map<String, SBQQ__QuoteLine__c> suggestedProducts = new Map<String, SBQQ__QuoteLine__c>();
            Map<String, SBR_3_0_API_ConsumablesResponse.Products> suggestedResponseProducts = new Map<String, SBR_3_0_API_ConsumablesResponse.Products>();
            List<SBQQ__QuoteLine__c> lineItemList = new List<SBQQ__QuoteLine__c>();
            List<SBQQ__QuoteLine__c> allQuoteLines = new List<SBQQ__QuoteLine__c>();
            Map<String, String> mapSKUandRateBranch = new  Map<String, String>();
            for(SBQQ__QuoteLine__c quoteLineItem : quoteLineItems){
                if(quoteLineItem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS){
                    catClassProducts.put(quoteLineItem.SBQQ__Product__r.Product_SKU__c, quoteLineItem);
                    if(catClassProductsListMap.containsKey(quoteLineItem.SBQQ__Product__r.Product_SKU__c))
                    {
                        lineItemList = new List<SBQQ__QuoteLine__c>();
                        lineItemList = catClassProductsListMap.get(quoteLineItem.SBQQ__Product__r.Product_SKU__c);
                        lineItemList.add(quoteLineItem);
                        catClassProductsListMap.put(quoteLineItem.SBQQ__Product__r.Product_SKU__c, lineItemList);
                    }
                    else{
                        lineItemList = new List<SBQQ__QuoteLine__c>();
                        lineItemList.add(quoteLineItem);
                        catClassProductsListMap.put(quoteLineItem.SBQQ__Product__r.Product_SKU__c, lineItemList);
                        mapSKUandRateBranch.put(quoteLineItem.SBQQ__Product__r.Product_SKU__c ,quoteLineItem.Rates_Branch__c);
                    }
                } else if((quoteLineItem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.PARTS || quoteLineItem.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || quoteLineItem.SBQQ__Product__r.Product_Type__c == 'MISC Charge Items')) {
                    suggestedProducts.put((quoteLineItem.SBQQ__Product__r.Stock_Class__c + quoteLineItem.SBQQ__Product__r.Item_Number__c), quoteLineItem);
                    if(suggestedProductsListMap.containsKey(quoteLineItem.SBQQ__Product__r.Stock_Class__c + quoteLineItem.SBQQ__Product__r.Item_Number__c))
                    {
                        lineItemList = new List<SBQQ__QuoteLine__c>();
                        lineItemList = suggestedProductsListMap.get(quoteLineItem.SBQQ__Product__r.Stock_Class__c + quoteLineItem.SBQQ__Product__r.Item_Number__c);
                        lineItemList.add(quoteLineItem);
                        suggestedProductsListMap.put(quoteLineItem.SBQQ__Product__r.Stock_Class__c + quoteLineItem.SBQQ__Product__r.Item_Number__c, lineItemList);
                    }
                    else{
                        lineItemList = new List<SBQQ__QuoteLine__c>();
                        lineItemList.add(quoteLineItem);
                        suggestedProductsListMap.put(quoteLineItem.SBQQ__Product__r.Stock_Class__c + quoteLineItem.SBQQ__Product__r.Item_Number__c, lineItemList);
                        
                    }
                }
            }
            
            // Call Rates API for Main Products
            if(!catClassProducts.isEmpty()) {
                String branchNumber = quoteRec.Jobsite__r.Branch__r.Branch_Location_Number__c;
                if (String.isBlank(branchNumber)) {
                    branchNumber = quoteRec.Branch__r.Branch_Location_Number__c;
                }
                SBR_3_0_API_RatesResponseWrapper respWrapper = SBR_3_0_API_Rates.getRatesFromRatesAPI(branchNumber, 
                                                                                                      quoteRec.SBQQ__Account__r.RM_Account_Number__c, 
                                                                                                      quoteRec.Jobsite__r.JobsiteName__c, quoteRec.SBQQ__Account__r.Company_Code__c,mapSKUandRateBranch);
                
                for(SBR_3_0_API_RatesResponseWrapper.Items item: respWrapper.data.items){
                    catClassResponseProducts.put(item.productId, item);
                }
                
                
                for(String productSku: catClassProductsListMap.keySet() )
                {
                    for(SBQQ__QuoteLine__c quoteLine: catClassProductsListMap.get(productSku)){
                        
                        if(catClassResponseProducts.containsKey(quoteLine.SBQQ__Product__r.Product_SKU__c)){
                            
                            quoteLine.Min_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.SBQQ__Product__r.Product_SKU__c).rates.suggestedRates.minimum);
                            quoteLine.Hourly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.SBQQ__Product__r.Product_SKU__c).rates.suggestedRates.minimum);
                            quoteLine.Daily_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.SBQQ__Product__r.Product_SKU__c).rates.suggestedRates.daily);
                            quoteLine.Weekly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.SBQQ__Product__r.Product_SKU__c).rates.suggestedRates.weekly);
                            quoteLine.Monthly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.SBQQ__Product__r.Product_SKU__c).rates.suggestedRates.monthly);
                            
                            quoteLine.Suggested_Minimum_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.SBQQ__Product__r.Product_SKU__c).rates.suggestedRates.minimum);
                            quoteLine.Suggested_Hourly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.SBQQ__Product__r.Product_SKU__c).rates.suggestedRates.minimum);                        
                            quoteLine.Suggested_Daily_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.SBQQ__Product__r.Product_SKU__c).rates.suggestedRates.daily);
                            quoteLine.Suggested_Weekly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.SBQQ__Product__r.Product_SKU__c).rates.suggestedRates.weekly);
                            quoteLine.Suggested_Monthly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.SBQQ__Product__r.Product_SKU__c).rates.suggestedRates.monthly);
                            allQuoteLines.add(quoteLine);
                        } else {
                            //throw new SBR_3_0_API_Rates_Exception('Product Rates Not Found for: ' + orderLine.Product2.Product_SKU__c);
                        }
                    }
                }
                // for Consumables Parts and Merchandise  
                if(!suggestedProducts.isEmpty()) {
                    //if(false){
                    // Call Consumables API for Suggested Products
                    SBR_3_0_API_ConsumablesResponse consResp = SBR_3_0_API_Rates.getRatesFromConsumablesAPI(branchNumber, 
                                                                                                            quoteRec.SBQQ__Account__r.RM_Account_Number__c, 
                                                                                                            quoteRec.Jobsite__r.Job_Number__c, 
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
                    
                    
                    // Populate Rates for Suggested Products
                    
                    for(String itemNum : suggestedProductsListMap.keySet() )
                    {
                        for(SBQQ__QuoteLine__c quoteLine: suggestedProductsListMap.get(itemNum)){
                            if(suggestedResponseProducts.containsKey(quoteLine.SBQQ__Product__r.Stock_Class__c + quoteLine.SBQQ__Product__r.Item_Number__c)){
                                quoteLine.Selling_Price__c = Decimal.valueOf(suggestedResponseProducts.get((quoteLine.SBQQ__Product__r.Stock_Class__c + quoteLine.SBQQ__Product__r.Item_Number__c)).sellingPrice);
                                allQuoteLines.add(quoteLine);
                                
                            } 
                        }}
                }
                
                
                if(!allQuoteLines.isEmpty()){
                    update  allQuoteLines;
                }
            }
        }
    }
    
    
    public class CloneRequest{
        
        @InvocableVariable(required=true)
        public String quoteId;
        
        @InvocableVariable(required=true)
        public string objectName;
        
        @InvocableVariable(required=true)
        public Boolean isAccountOrJobSiteChanged;
    }
    
    
    Public class cloneResponse {
        @InvocableVariable
        Public Boolean isSuccess;
        
    }
}