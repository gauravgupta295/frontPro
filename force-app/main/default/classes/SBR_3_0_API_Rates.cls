/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_Rates
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Fetch Product Rates from Wayne ERP (RentalMan) using Mulesoft
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
1.0         Hashem Abdul          2022-04-14            Initial version
1.1         Hashem Abdul          2022-09-20            SAL-2982 - Refresh Quote Rate    
*********************************************************************************************************************/
public without sharing class SBR_3_0_API_Rates {
    private static final String APINAME = 'Rates_API_V2';

    @AuraEnabled
    public static String getRates(String ratesRequestJson, String companyId){
        String returnPayload = '';

        returnPayload = SBR_3_0_Generic_Callout.callEndpoint(ratesRequestJson, APINAME, companyId);
        
        return returnPayload;
    }
    // for testing purpose , do not deploy 
    @AuraEnabled
    public static String getRatesNew(String ratesRequestJson, String companyId){
        String returnPayload = '';
        System.debug('\n @@rates request = ' + JSON.serializePretty(ratesRequestJson));
        returnPayload = SBR_3_0_Generic_Callout.callEndpoint(ratesRequestJson, 'Rates_API_New', companyId);
        
        return returnPayload;
    }

    @AuraEnabled
    public static String refreshQuoteRates(Id quoteId) {
        String returnVal = '';
        try {
            User currentUser = SBR_3_0_UserDA.getUserById(UserInfo.getUserId());
            SBQQ__Quote__c currentQuote = SBR_3_0_QuoteDA.getQuote(quoteId);
            // SAL-26606
            if (((currentUser.UserRole.Name == 'Sales - US' || currentUser.UserRole.Name == 'Sales - CA') && currentQuote.OwnerId == currentUser.Id) || ((currentUser.UserRole.Name == 'Sales - US' || currentUser.UserRole.Name == 'Sales - CA') && currentQuote.CreatedById == currentUser.Id) || (currentUser.UserRole.Name <> 'Sales - US' && currentUser.UserRole.Name <> 'Sales - CA')) {
                returnVal = updateQuoteRate(quoteId);
            } else {
                throw new SBR_3_0_API_Rates_Exception('Sales Reps can only access this function for records they own. Please reach out to your manager if you need to update this record.');
            }
        } catch (Exception e) {
            throw new AuraHandledException(e.getMessage());
        }
        return returnVal;
    }
    
    public static SBR_3_0_API_RatesResponseWrapper getRatesFromRatesAPI(String branchNumber, String accountNumber, String jobSiteName, String companyCode, Map<String, String> mapSKUandRateBranch) {
        SBR_3_0_API_RatesRequestWrapper reqWrapper = new SBR_3_0_API_RatesRequestWrapper();
        if (String.isEmpty(companyCode)) {
            throw new SBR_3_0_API_Rates_Exception('Company code is required');
        }
        /*if (String.isNotEmpty(branchNumber)) {
            reqWrapper.pc = Integer.valueOf(branchNumber);
        } else {
            throw new SBR_3_0_API_Rates_Exception('Branch Number is required');
        }*/
        if (mapSKUandRateBranch.isEmpty()) {
            System.debug('\n @@mapSKUandRateBranch 1 =' + mapSKUandRateBranch);
            throw new SBR_3_0_API_Rates_Exception('Products cannot be empty');
        } else {
            System.debug('\n @@mapSKUandRateBranch 2 =' + mapSKUandRateBranch);
            reqWrapper.products = new List<SBR_3_0_API_RatesRequestWrapper.Products>();
            for (String prodSku : mapSKUandRateBranch.keyset()) {
                SBR_3_0_API_RatesRequestWrapper.Products prod = new SBR_3_0_API_RatesRequestWrapper.Products();
                prod.productId = prodSku;
                prod.pc = mapSKUandRateBranch.get(prodSku);
                reqWrapper.products.add(prod);
            }
        }
        if (String.isNotEmpty(accountNumber)) {
            if (accountNumber.contains('-')) {
                accountNumber = accountNumber.subStringAfter('-');
            }
            reqWrapper.accountNumber = accountNumber;
        }
        if (String.isNotEmpty(jobSiteName)) {
            reqWrapper.jobsite = jobSiteName;
        }
        //throw new SBR_3_0_API_Rates_Exception(JSON.serialize(reqWrapper));
        String response = getRates(JSON.serialize(reqWrapper), companyCode);

        SBR_3_0_API_RatesResponseWrapper respWrapper = (SBR_3_0_API_RatesResponseWrapper) JSON.deserialize(response, SBR_3_0_API_RatesResponseWrapper.class);
        return respWrapper;
    }


    public static SBR_3_0_API_ConsumablesResponse getRatesFromConsumablesAPI(String branchNumber, String accountNumber, String jobSiteNumber, String companyCode, Set<String> productSKUs) {
        SBR_3_0_API_ConsumablesRequest reqWrapper = new SBR_3_0_API_ConsumablesRequest();
        if (String.isEmpty(companyCode)) {
            throw new SBR_3_0_API_Rates_Exception('Company code is required');
        }
        if (companyCode.length() == 1 && !companyCode.startsWith('0')) {
            companyCode = '0' + companyCode;
        }

        if (String.isNotEmpty(branchNumber)) {
            reqWrapper.pc = branchNumber;
        }

        if (productSKUs.isEmpty()) {
            throw new SBR_3_0_API_Rates_Exception('Products cannot be empty');
        } else {
            reqWrapper.products = new List<SBR_3_0_API_ConsumablesRequest.Products>();
            for (String prodSku : productSKUs) {
                SBR_3_0_API_ConsumablesRequest.Products prod = new SBR_3_0_API_ConsumablesRequest.Products();
                prod.catId = prodSku.substring(0, 3);
                prod.classId = prodSku.substring(3);
                reqWrapper.products.add(prod);
            }
        }

       /*if (String.isNotEmpty(accountNumber) && accountNumber.contains('-')) {
            accountNumber = accountNumber.subStringAfter('-');
        }
        reqWrapper.accountNumber = accountNumber;

        if (String.isNotEmpty(jobSiteNumber)) {
            reqWrapper.jobsiteNumber = jobSiteNumber;
        }*/
        //throw new SBR_3_0_API_Rates_Exception(JSON.serialize(reqWrapper));

        String response = SBR_3_0_API_Consumables.getConsumableRates(JSON.serialize(reqWrapper), companyCode);

        SBR_3_0_API_ConsumablesResponse respWrapper = (SBR_3_0_API_ConsumablesResponse) JSON.deserialize(response, SBR_3_0_API_ConsumablesResponse.class);
        return respWrapper;
    }




    public static String updateQuoteRate(Id quoteId) {
        String returnVal = '';
        SBR_3_0_API_RatesRequestWrapper reqWrapper = new SBR_3_0_API_RatesRequestWrapper();
        List<SBQQ__QuoteLine__c> allQuoteLines = new List<SBQQ__QuoteLine__c>();
        Map<Id, SBQQ__Quote__c> quote = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{ quoteId });
        String companyCode = '';
        if (!quote.isEmpty()) {
            SBQQ__Quote__c quoteRec = quote.values()[0];
            companyCode = quoteRec.SBQQ__Account__r.Company_Code__c;
            if (companyCode.length() == 1 && !companyCode.startsWith('0')) {
                companyCode = '0' + companyCode;
            }
            // Separate Cat-Class Product types
            Map<String, SBQQ__QuoteLine__c> catClassProducts = new Map<String, SBQQ__QuoteLine__c>();
            Map<String, List<SBQQ__QuoteLine__c>> catClassProductsListMap = new Map<String, List<SBQQ__QuoteLine__c>>();
            Map<String, SBR_3_0_API_RatesResponseWrapper.Items> catClassResponseProducts = new Map<String, SBR_3_0_API_RatesResponseWrapper.Items>();
            Map<String, SBQQ__QuoteLine__c> suggestedProducts = new Map<String, SBQQ__QuoteLine__c>();
            Map<String, List<SBQQ__QuoteLine__c>> suggestedProductsListMap = new Map<String, List<SBQQ__QuoteLine__c>>();
            Map<String, SBR_3_0_API_ConsumablesResponse.Products> suggestedResponseProducts = new Map<String, SBR_3_0_API_ConsumablesResponse.Products>();

            List<SBQQ__QuoteLine__c> lineItemList = new List<SBQQ__QuoteLine__c>();
            Map<String, String> mapSKUandRateBranch = new  Map<String, String>();
            for (SBQQ__QuoteLine__c quoteLine : quoteRec.SBQQ__LineItems__r) {
                if (quoteLine.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.CAT_CLASS) {
                    catClassProducts.put(quoteLine.Product_SKU__c, quoteLine);
                    if (catClassProductsListMap.containsKey(quoteLine.Product_SKU__c)) {
                        lineItemList = new List<SBQQ__QuoteLine__c>();
                        lineItemList = catClassProductsListMap.get(quoteLine.Product_SKU__c);
                        lineItemList.add(quoteLine);
                        catClassProductsListMap.put(quoteLine.Product_SKU__c, lineItemList);
                    } else {
                        lineItemList = new List<SBQQ__QuoteLine__c>();
                        lineItemList.add(quoteLine);
                        catClassProductsListMap.put(quoteLine.Product_SKU__c, lineItemList);
                        mapSKUandRateBranch.put(quoteLine.Product_SKU__c ,quoteLine.Rates_Branch__c);
                    }
                } else if ((quoteLine.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.PARTS || quoteLine.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || quoteLine.SBQQ__Product__r.Product_Type__c == 'MISC Charge Items')) {
                    suggestedProducts.put(quoteLine.SBQQ__Product__r.Stock_Class__c + quoteLine.SBQQ__Product__r.Item_Number__c, quoteLine);
                    if (suggestedProductsListMap.containsKey(quoteLine.SBQQ__Product__r.Stock_Class__c + quoteLine.SBQQ__Product__r.Item_Number__c)) {
                        lineItemList = new List<SBQQ__QuoteLine__c>();
                        lineItemList = suggestedProductsListMap.get(quoteLine.SBQQ__Product__r.Stock_Class__c + quoteLine.SBQQ__Product__r.Item_Number__c);
                        lineItemList.add(quoteLine);
                        suggestedProductsListMap.put(quoteLine.SBQQ__Product__r.Stock_Class__c + quoteLine.SBQQ__Product__r.Item_Number__c, lineItemList);
                    } else {
                        lineItemList = new List<SBQQ__QuoteLine__c>();
                        lineItemList.add(quoteLine);
                        suggestedProductsListMap.put(quoteLine.SBQQ__Product__r.Stock_Class__c + quoteLine.SBQQ__Product__r.Item_Number__c, lineItemList);
                    }
                }
            }

            // Call Rates API for Main Products
            if (!catClassProducts.isEmpty()) {
                String branchNumber = quoteRec.Jobsite__r.Branch__r.Branch_Location_Number__c;
                if (String.isBlank(branchNumber)) {
                    branchNumber = quoteRec.Branch__r.Branch_Location_Number__c;
                }
                SBR_3_0_API_RatesResponseWrapper respWrapper = getRatesFromRatesAPI(branchNumber, quoteRec.SBQQ__Account__r.RM_Account_Number__c, quoteRec.Jobsite__r.JobsiteName__c, quoteRec.SBQQ__Account__r.Company_Code__c, mapSKUandRateBranch);

                for (SBR_3_0_API_RatesResponseWrapper.Items item : respWrapper.data.items) {
                    catClassResponseProducts.put(item.productId, item);
                }
                // Populate Rates for Cat-Class Products
                //integer i = 1;

                for (String productSku : catClassProductsListMap.keySet()) {
                    for (SBQQ__QuoteLine__c quoteLine : catClassProductsListMap.get(productSku)) {
                        if (catClassResponseProducts.containsKey(quoteLine.Product_SKU__c)) {
                            quoteLine.Min_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.Product_SKU__c).rates.suggestedRates.minimum);
                            quoteLine.Hourly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.Product_SKU__c).rates.suggestedRates.minimum);
                            quoteLine.Daily_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.Product_SKU__c).rates.suggestedRates.daily);
                            quoteLine.Weekly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.Product_SKU__c).rates.suggestedRates.weekly);
                            quoteLine.Monthly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.Product_SKU__c).rates.suggestedRates.monthly);

                            quoteLine.Suggested_Minimum_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.Product_SKU__c).rates.suggestedRates.minimum);
                            quoteLine.Suggested_Hourly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.Product_SKU__c).rates.suggestedRates.minimum);
                            quoteLine.Suggested_Daily_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.Product_SKU__c).rates.suggestedRates.daily);
                            quoteLine.Suggested_Weekly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.Product_SKU__c).rates.suggestedRates.weekly);
                            quoteLine.Suggested_Monthly_Rate__c = Decimal.valueOf(catClassResponseProducts.get(quoteLine.Product_SKU__c).rates.suggestedRates.monthly);
                            //reset seasonal rate and multiplier for the line item edit UI
                            quoteLine.Seasonal_Rate__c = 0;
                            quoteLine.Seasonal_Multiplier__c = 4;
                            allQuoteLines.add(quoteLine);
                        } else {
                            throw new SBR_3_0_API_Rates_Exception('Product Rates Not Found for: ' + quoteLine.Product_SKU__c);
                        }
                    }
                }

                if (!suggestedProducts.isEmpty()) {
                    // Call Consumables API for Suggested Products
                    
                    SBR_3_0_API_ConsumablesResponse consResp = getRatesFromConsumablesAPI(branchNumber, quoteRec.SBQQ__Account__r.RM_Account_Number__c, quoteRec.Jobsite__r.Job_Number__c, companyCode, catClassProducts.keySet());


                    for (SBR_3_0_API_ConsumablesResponse.SuggestedItems suggItem : consResp.data.suggestedItems) {
                        for (SBR_3_0_API_ConsumablesResponse.Consumables consumble : suggItem.consumables) {
                            for (SBR_3_0_API_ConsumablesResponse.SpecGroups specGrp : consumble.specGroups) {
                                for (SBR_3_0_API_ConsumablesResponse.Products prd : specGrp.products) {
                                    //String prdSku = companyCode + '-' + prd.stockClass + '-' + prd.productNumber;
                                    String prdSku = prd.stockClass + prd.productNumber;
                                    suggestedResponseProducts.put(prdSku, prd);
                                }
                            }
                        }
                    }

                    for (String itemNum : suggestedProductsListMap.keySet()) {
                        for (SBQQ__QuoteLine__c quoteLine : suggestedProductsListMap.get(itemNum)) {
                            if (suggestedResponseProducts.containsKey(quoteLine.SBQQ__Product__r.Stock_Class__c + quoteLine.SBQQ__Product__r.Item_Number__c)) {
                                quoteLine.Selling_Price__c = Decimal.valueOf(suggestedResponseProducts.get(quoteLine.SBQQ__Product__r.Stock_Class__c + quoteLine.SBQQ__Product__r.Item_Number__c).sellingPrice);
                                allQuoteLines.add(quoteLine);
                            }
                        }
                    }
                }

                if (!allQuoteLines.isEmpty()) {
                    update allQuoteLines;
                }
            }
        }
        return returnVal;
    }

    @InvocableMethod(callout=true label='Refresh Quote Rate')
    public static List<Boolean> refreshQuoteRateInvocable(List<String> quoteId) {
        List<Boolean> returnVal = new List<Boolean>();
        try {
            updateQuoteRate(quoteId[0]);
            returnVal.add(true);
        } catch (Exception ex) {
            returnVal.add(false);
        }

        return returnVal;
    }

    public class SBR_3_0_API_Rates_Exception extends Exception {
    }
}