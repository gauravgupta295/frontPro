/*********************************************************************************************************************
* Apex Class: SBR_3_0_API_CreateQuotesV2
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Send Quote to Rentalman (via Mulesoft) when it is created in Salesforce
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Neeraj Kumar         2022-09-23             Initial version    
*********************************************************************************************************************/
public without sharing class SBR_3_0_API_CreateQuotesV2 {
    private static final String APINAME = 'Create_Quotes_API_V2';
    private static final String UPDATEAPINAME = 'Edit_Quotes_API_V2';
    private Id quoteId;
    private String companyId;
    private SBQQ__Quote__c quote;
    private Object response;
    private Map<Integer, SBQQ__QuoteLine__c> mapQuoteItem;
    private Integer responseStatusCode;
    private string servicePayload;
    private static final String DATA = 'data';
    private static final String RM_QUOTE_ID = 'rmQuoteId';
    private static final String LINES = 'lines';
    private static final String RM_LINE_NUMBER = 'rmLineNumber';
    private static final String GLOBAL_LINE_NUMBER = 'lineNumber';
    private static final String RM_LINE_TYPE = 'rmLineType';
    private static final String ERROR = 'error';
    private static final String SUCCESS = 'success';
    private static final String SF_LINE_NUMBER = 'sfLineNumber';
    
    private String currentUserWynneUserName;

    @AuraEnabled
    public static object submitQuote(Id quoteId) {
        SBR_3_0_API_CreateQuotesV2 quoteInstance = new SBR_3_0_API_CreateQuotesV2();
        return quoteInstance.submit(quoteId);
    }
    public object submit (Id quoteId) {
        string responseBody;
        Set<Id> quoteIds;
        Map<Id, SBQQ__Quote__c> quotes;
        this.quoteId = quoteId;
        quoteIds = new Set<Id>();
        mapQuoteItem = new Map<Integer, SBQQ__QuoteLine__c>();
        quoteIds.add(quoteId);
        quotes = new Map<Id, SBQQ__Quote__c>(SBR_3_0_QuoteDA.getQuotes(quoteIds));
        quote = quotes.get(quoteId);
        this.companyId = !String.isBlank(quote.Company_Code__c) ? quote.Company_Code__c : '01';
        if(!Test.isRunningTest()) {
            this.currentUserWynneUserName = [SELECT Id,Wynne_User_Name__c FROM User WHERE Id= :UserInfo.getUserId()].Wynne_User_Name__c;
        } else {
            this.currentUserWynneUserName=UserInfo.getUserId();
        }
        validateData();
        servicePayload =  SBR_3_0_CreateQuotesPayloadGenerator.generatePayload(quote);
        if(quote.Rentalman_Quote_Id__c == null ) {
            responseBody = createQuote();
        } else {
            responseBody = updateQuote();
        }
        handleQuoteResponse();
        return responseBody;
    }
    
    private string createQuote(){
        HTTPResponse returnPayload;
        Map<String,String> headers = new Map<String,String>();
        headers.put('x-correlation-id',SBR_3_0_Generic.generateRandomString(10));
        headers.put('companyId' ,this.companyId);
        SBR_3_0_Generic_Callout.setHeaders(headers);
        returnPayload = SBR_3_0_Generic_Callout.callEndpoint(servicePayload, APINAME);
        responseStatusCode = returnPayload.getStatusCode();
        System.debug('\n @@ HTTPresponse =' + returnPayload);
        response = JSON.deserializeUntyped(returnPayload.getBody());
        System.debug('\n @@ response =' + response);
        return returnPayload.getBody();
    }
    private string updateQuote(){
        HTTPResponse returnPayload;
        Map<String,String> headers = new Map<String,String>();
        headers.put('x-correlation-id',SBR_3_0_Generic.generateRandomString(10));
        headers.put('companyId' ,this.companyId);
        SBR_3_0_Generic_Callout.setHeaders(headers);
        List<String> pathParams = new List<String>();
        pathParams.add(quote.Rentalman_Quote_Id__c);
        SBR_3_0_Generic_Callout.setURLParams(pathParams);
        returnPayload = SBR_3_0_Generic_Callout.callEndpoint(servicePayload, UPDATEAPINAME);
        responseStatusCode = returnPayload.getStatusCode();
        System.debug('\n @@ HTTPresponse =' + returnPayload);
        response = JSON.deserializeUntyped(returnPayload.getBody());
        System.debug('\n @@ response =' + response);
        return returnPayload.getBody();
    }
     private void validateData() {
        if (quote.Ordered_by__r.LastName == null) {
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_OrdrByLstName_ErrMsg);
        }
        if (quote.Ordered_by__r.FirstName == null) {
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_OrdrByFrstName_ErrMsg);
        }
        if(quote.SBQQ__SalesRep__r.RepID__c == null){
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_SalesRepId_ErrMsg);
        }
        if(quote.SBQQ__Account__r.Record_Type_Text__c != 'Non-Credit'){
            if(quote.RM_Account_Number__c == null){
                throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_RMAccNumber_ErrMsg);
            }
        }
        if(quote.SBQQ__Account__r.Phone == null){
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_AccPhone_ErrMsg); 
        }
        if(this.currentUserWynneUserName == null){
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_WynneName_ErrMsg);
        }
        if (quote.Ordered_By__r.Email == null) {
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_OrderByEmail_ErrMsg);
        }
        if (quote.Ordered_By__r.Phone == null){
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_OrderByPhone_ErrMsg);
        }
        if (quote.Ordered_By__r.Phone != null && quote.Ordered_By__r.Phone.length() < 10){
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_OrderByPhoneNotValid_ErrMsg);
        }
        if (quote.End_Date__c  == null) {
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_ReturnDate_ErrMsg);
        }
        if(quote.SBQQ__Account__r.Record_Type_Text__c != 'Non-Credit'){
            if(quote.Jobsite__r == null) {
                throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_Jobsite_ErrMsg);
            } else {
                if(quote.Jobsite__r.Branch__r == null) {
                    throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_Branch_ErrMsg);
                } else {
                    if(quote.Jobsite__r.Branch__r.Branch_Location_Number__c == null) {
                        throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_BrnchLocationNmbr_ErrMsg);
                    }
                    if(quote.Jobsite__r.Branch__r.Time_Zone_Id__c == null) {
                        throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_LocationTimeZoneId_ErrMsg);
                    }
                }
                if (quote.Jobsite__r.Location == null) {
                    throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_JobsiteAddress_ErrMsg);
                } else {
                    if(quote.Jobsite__r.Location.OMS_Sourcing_Enabled__c == null) {
                        throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_JobsiteLocationOMSSourcingEnabled_ErrMsg);
                    }
                    if (quote.Jobsite__r.LocationId == null) {
                        throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_JobsiteLocationId_ErrMsg);
                    }
                    if (quote.Jobsite__r.Job_Number__c == null) {
                        throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_JobsiteJobNumber_ErrMsg);
                    }
                }
            }
        }
        for(SBQQ__QuoteLine__c  quoteItemRec: quote.SBQQ__LineItems__r) {
            mapQuoteItem.put(Integer.valueOf(quoteItemRec.QuoteItemNumber__c), quoteItemRec);
            if(quoteItemRec.SBQQ__Product__r.Product_Type__c == 'Cat-Class') {
                validateProduct(quoteItemRec);
            } else if(quoteItemRec.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.PARTS || quoteItemRec.SBQQ__Product__r.Product_Type__c == SBR_3_0_Constants.MERCHANDISE || (quoteItemRec.is_User_Added__c && (quoteItemRec.SBQQ__Product__r.Product_Type__c == 'MISC Charge Items' || quoteItemRec.SBQQ__Product__r.Product_Type__c == 'Misc-Charge'))){
                validateSaleItem(quoteItemRec);
            }
        }
     }
    
    private void validateProduct(SBQQ__QuoteLine__c quoteItem) {
         if (quoteItem.Misc_Charges_Type__c  == null) {
            if (quoteItem.Daily_Rate__c == null) {
                throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_DailyRate_ErrMsg);
            }
            if (quoteItem.Weekly_Rate__c == null) {
                throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_WeeklyRate_ErrMsg);
            }
            if (quoteItem.Monthly_Rate__c == null) {
                throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_MonthlyRate_ErrMsg);
            }
            if (quoteItem.Min_Rate__c == null) {
                throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_MinRate_ErrMsg);
            }
            if (quoteItem.SBQQ__Quantity__c  == null) {
                throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_Quantity_ErrMsg);
            }
            if (quoteItem.SBQQ__Product__r.Category__c == null) {
                throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_ProductCategory_ErrMsg);
            }
            if (quoteItem.SBQQ__Product__r.Class__c == null) {
                throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_ProductClass_ErrMsg);
            }
        }
    }

    private void validateSaleItem(SBQQ__QuoteLine__c quoteLine) {
        if (quoteLine.SBQQ__Product__r.Item_Number__c == null) {
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_ProductOrderItemNumber_ErrMsg);
        }
        if (quoteLine.SBQQ__Product__r.Stock_Class__c == null) {
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_ProductStockClass_ErrMsg);
        }
        if (quoteLine.SBQQ__Quantity__c == null) {
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_QuantitySalesItem_ErrMsg);
        }
        if (quoteLine.Selling_Price__c == null || quoteLine.Selling_Price__c == 0) {
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_SellingPriceSalesItem_ErrMsg);
        }
        if(quoteLine.Unit_of_Measure__c == null){
            throw new CreateQuoteException(Label.SBR_3_0_OrderAPI_OrderItemUntOfMsr_ErrMsg);
        }
    }

    private void handleQuoteResponse() {
       
        String errorMsg  = '';
       
            if(response != null && response instanceof Map<String, Object>) {
                Map<String, Object> resultMap = (Map<String, Object>)response;
                if(resultMap.containsKey(DATA) && resultMap.get(DATA) instanceof Map<String, Object>){
                    Map<String, Object> data = (Map<String, Object>)resultMap.get(DATA);
                    if(data.containsKey(RM_QUOTE_ID) && quote.Rentalman_Quote_Id__c== null){
                        String rmQuoteId = String.valueOf(data.get(RM_QUOTE_ID));
                        quote.Rentalman_Quote_Id__c = rmQuoteId;
                        quote.Is_Edit_In_Progress__c = false;
                        quote.Last_Edit_By__c = null;
                        quote.SBQQ__Status__c = 'Submitted';
                        quote.Submitted_to_Wynne__c = true;
                        update quote;
                    }
                    if(data.containsKey(LINES)){
                        List<Object> linesData =(List<Object>)data.get(LINES);
                        for(Object line : linesData) {
                            Map<String, Object> linesMap= (Map<String, Object>) line;
                            String lineNumber = (String) linesMap.get(SF_LINE_NUMBER);
                            Integer lineNo = (lineNumber!= null && lineNumber != '')?Integer.valueOf(lineNumber):null;
                            if(mapQuoteItem.containsKey(lineNo)) {
                                SBQQ__QuoteLine__c ordItem = mapQuoteItem.get(lineNo);
                                ordItem.RM_Quote_Line_Number__c = Integer.valueOf(linesMap.get(RM_LINE_NUMBER));
                                ordItem.Line_Item_Type__c = (String)linesMap.get(RM_LINE_TYPE);
                                ordItem.Global_Line_Number__c = Integer.valueOf(linesMap.get(GLOBAL_LINE_NUMBER));
                                ordItem.Line_Composite_Key__c = quote.Rentalman_Quote_Id__c + '-' +ordItem.Global_Line_Number__c;
                            }
                        }
                        quote.Is_Edit_In_Progress__c = false;
                        quote.Last_Edit_By__c = null;
                        update quote;
                        update mapQuoteItem.values();
                    }
                    
                } else if(resultMap.containsKey(ERROR) && resultMap.get(ERROR) instanceof Map<String, Object>) {
                    Integer[] codeArray  = new Integer[] {400,401,404,405,406,415,422,500};
                    if(codeArray.contains(responseStatusCode)) {
                        Map<String, Object> error = (Map<String, Object>)resultMap.get(ERROR);
                        errorMsg = 
                            ' message: ' +
                            error.get('message') +
                            ' errorKey: ' +
                            error.get('errorKey') +
                            ' errorCode: ' +
                            error.get('errorCode');
                    } else {
                        errorMsg = 'This Quote  couldn’t be Submitted at this time due to an internal error, please try again.';
                    }
                    throw new CreateQuoteException(errorMsg);
                }
            }
     
    }
    public class CreateQuoteException extends Exception {}
    
    // COMMENTING THE BELOW CODE AS THE RATE VALIDATION STORIES ARE CURRENTLY UNTAGGED FROM THE SPRINT AND WILL COME IN FUTURE SPRINT

    // //FRONT-2185
    // public String validateQuote(List<SBQQ__QuoteLine__c> quoteItems, Id quoteId, Boolean isSales) {
    //     Map<Id, SBQQ__QuoteLine__c> quoteLineMap = new Map<Id, SBQQ__QuoteLine__c>(quoteItems);
    //     Map<Id, SBQQ__Quote__c> quotes = SBR_3_0_QuoteDA.getQuotes(new Set<Id>{quoteId});
    //     SBQQ__Quote__c quote = quotes.get(quoteId);
    //     SBR_3_0_EditQuotesWrapper quotePayload =  SBR_3_0_CreateQuotesPayloadGenerator.getPayloadWrapper(quote);
    //     servicePayload = updateLineItemValues(quotePayload, quoteLineMap, isSales);
    //     this.companyId = !String.isBlank(quote.Company_Code__c) ? quote.Company_Code__c : '01';        
        
    //     HTTPResponse returnPayload;
    //     Map<String,String> headers = new Map<String,String>();
    //     headers.put('x-correlation-id', SBR_3_0_Generic.generateRandomString(10));
    //     headers.put('companyId', this.companyId);
    //     headers.put('validate', 'true');
    //     SBR_3_0_Generic_Callout.setHeaders(headers);
    //     returnPayload = SBR_3_0_Generic_Callout.callEndpoint(servicePayload, APINAME);
    //     responseStatusCode = returnPayload.getStatusCode();
    //     System.debug('\n ====HTTPresponse====\n' + returnPayload + '====\nresponse====\n' + JSON.deserializeUntyped(returnPayload.getBody()));
    //     return returnPayload.getBody();
    // }
    
    // /*
    //  * FRONT-2185
    //  * Method used to replace the existing values with user edited by Users  
    // */ 
    // private String updateLineItemValues(SBR_3_0_EditQuotesWrapper quotePayload, Map<Id, SBQQ__QuoteLine__c> quoteLineMap, Boolean isSales) {
    //     List<SBR_3_0_EditQuotesWrapper.Products> updatedProducts = new List<SBR_3_0_EditQuotesWrapper.Products>();
    //     List<SBR_3_0_EditQuotesWrapper.SalesItems> updatedSalesItems = new List<SBR_3_0_EditQuotesWrapper.SalesItems>();
    //     Map<Id, SBQQ__QuoteLine__c> quoteLineValuesMap = getQuoteItems(quoteLineMap.keySet());
        
    //     if(isSales) {
    //         for(SBR_3_0_EditQuotesWrapper.salesItems salesItem: quotePayload.salesItems) {
    //             if(quoteLineMap.containsKey(salesItem.lineItemId)) {
    //                 SBQQ__QuoteLine__c quoteItemJS = quoteLineMap.get(salesItem.lineItemId);
    //                 SBQQ__QuoteLine__c quoteItemDB = quoteLineValuesMap.get(salesItem.lineItemId);
    //                 salesItem.rmLineNumber = quoteItemDB.RM_Quote_Line_Number__c?.intValue();
    //                 salesItem.sfLineNumber = String.valueOf(quoteItemDB.QuoteItemNumber__c);
    //                 salesItem.itemNumber = quoteItemDB.SBQQ__Product__r.Item_Number__c;
    //                 salesItem.quantity = quoteItemJS.SBQQ__Quantity__c?.intValue();
    //                 salesItem.stockClass = quoteItemDB.SBQQ__Product__r.Stock_class__c;
    //                 salesItem.unitPrice = quoteItemJS.Selling_Price__c;
    //                 salesItem.unitOfMeasure = quoteItemDB.Unit_of_Measure__c;
    //                 salesItem.lineComment = quoteItemDB.Line_Comments__c;   
    //                 updatedSalesItems.add(salesItem);
    //             }
    //         }
    //     } else {
    //         for(SBR_3_0_EditQuotesWrapper.Products product: quotePayload.Products) {
    //             if(quoteLineMap.containsKey(product.lineItemId)) {
    //                 SBQQ__QuoteLine__c quoteItemJS = quoteLineMap.get(product.lineItemId);
    //                 SBQQ__QuoteLine__c quoteItemDB = quoteLineValuesMap.get(product.lineItemId);
    //                 product.rmLineNumber = quoteItemDB.RM_Quote_Line_Number__c?.intValue();
    //                 product.sfLineNumber = String.valueOf(quoteItemDB.QuoteItemNumber__c);
    //                 product.quantity = quoteItemJS.SBQQ__Quantity__c?.intValue();
    //                 product.minimumRate = quoteItemJS.Min_Rate__c;
    //                 product.hourRate = quoteItemJS.Hourly_Rate__c != null ? quoteItemJS.Hourly_Rate__c : 0;
    //                 product.actualRates.day = quoteItemJS.Daily_Rate__c;
    //                 product.actualRates.weekly = quoteItemJS.Weekly_Rate__c;
    //                 product.actualRates.monthly = quoteItemJS.Monthly_Rate__c;
    //                 updatedProducts.add(product);
    //             }
    //         }
    //     }
    //     quotePayload.Products = updatedProducts;
    //     quotePayload.salesItems = updatedSalesItems;
    //     System.debug('\n====validateQuote=Request===\n' + JSON.serializePretty(quotePayload));
    //     return JSON.serialize(quotePayload, true);
    // }
    
    // private static Map<Id, SBQQ__QuoteLine__c> getQuoteItems(Set<Id> quoteItemIds) {
    //     return new Map<Id, SBQQ__QuoteLine__c>([
    //         SELECT 
    //         	RM_Quote_Line_Number__c, QuoteItemNumber__c, SBQQ__Product__r.Item_Number__c, 
    //         	SBQQ__Product__r.Stock_class__c, Unit_of_Measure__c, Line_Comments__c
    //         FROM SBQQ__QuoteLine__c
    //         WHERE Id IN: quoteItemIds
    //     ]);
    // }
}