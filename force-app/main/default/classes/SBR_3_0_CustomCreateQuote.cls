/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomCreateQuote
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Helper class for creating Quote request passed from Rentalman to Salesforce using rest API in SBR_3_0_API_Web_Quote
---------------------------------------------------------------------------------------------------------------------------------------  
*********************************************************************************************************************/
public with sharing class SBR_3_0_CustomCreateQuote {
    private static QuoteRequestWrapper wq = new QuoteRequestWrapper();
    private static SBQQ__Quote__c inQuote; //Inbound Quote details to upsert 

    private static Boolean isNew = false;
    private static Boolean staleInboundOrder = false;
    private static Boolean hasAccountChanged = false;
    private static Boolean hasJobSiteChanged = false;
    private static Boolean hasBranchChanged = false;
    private static Boolean hasPrimarySaleRepChanged = false;
    private static Boolean hasSecSaleRepChanged = false;

    private static String branchTimeZoneOffset;
    private static String genericProductSku = 'x';
    private static final String SOBJECT_QUOTE = 'SBQQ__Quote__c';
    private static final String DELIVERY = 'DELIVERY';
    private static final String PICKUP = 'PICKUP';
    private static final String DELIVERY_DATE_FIELD = 'Delivery_Date__c';
    private static final String START_DATE_FIELD = 'Start_Date__c';
    private static Set<Integer> globalLineNumbersToDelete;

    private Map<String,SBQQ__QuoteLine__c> lineItemExistsMap = new Map<String,SBQQ__QuoteLine__c>();//SAL-23899

    public SBR_3_0_CustomCreateQuote(String req) {
        wq = (QuoteRequestWrapper)JSON.deserialize(req, QuoteRequestWrapper.class);
        inQuote = (SBQQ__Quote__c)JSON.deserialize(JSON.serialize(wq.data), SBQQ__Quote__c.class);
        if(req.contains('deletedLineData')) {
            setDeletedLineData(req);
        }
    }

    public String syncQuoteToSF() {
        SBQQ__Quote__c existing = sfQuote;
        //if(staleInboundOrder) {
        //    return 'Stale Order. A more recent Order update already exists! Ignoring the request ...';
        //}
        String quoteRecdId = loadQuote();
        if(String.isNotBlank(quoteRecdId) && !Test.isRunningTest()){
            System.enqueueJob(new SBR_3_0_QueueableUpdateQuoteTotals(quoteRecdId));
        }

        return quoteRecdId;
    }

    private String loadQuote() {
        SBQQ__Quote__c quoteToCreate = wq.data;
        inQuote.Rentalman_Quote_Id__c = rentalmanQuoteId;
        inQuote.Submitted_to_Wynne__c = true;
        inQuote.Quote_Initiating_Channel__c = 'Rentalman';

        inQuote.RM_Sales_Rep_Id__c = wq.primarySalesRep ; //SAL-25663

        if (String.isNotBlank(wq.data.SBQQ__Status__c ) && wq.data.SBQQ__Status__c == 'Cancelled'){
            inQuote.SBQQ__Status__c = wq.data.SBQQ__Status__c;
            upsert inQuote Rentalman_Quote_Id__c;
        }
        else{
            // Populate Account Id
            inQuote.SBQQ__Account__c = relAcct.Id;
            inQuote.Jobsite__c = (jobSite != null) ? jobSite.Id : createJobSite(inQuote).Id; //assign jobsiteId or create one
            inQuote.Branch__c = branchId;
            inQuote.RecordTypeId = (String.isNotBlank(wq.type)) ? rtMap.get(wq.type) : null;
            inQuote = setShipToContact(inQuote);
            inQuote = setAddress(inQuote);
            inQuote.SBQQ__SalesRep__c = (salesRepUserIds !=null && salesRepUserIds.containsKey(wq.primarySalesRep)) ? salesRepUserIds.get(wq.primarySalesRep).Id : null ; //Relate Sales Reps
            if(inQuote.SBQQ__SalesRep__c != null)
            {
                inQuote.OwnerId = inQuote.SBQQ__SalesRep__c;
            }
            inQuote.Secondary_Rep__c = (salesRepUserIds !=null && salesRepUserIds.containsKey(wq.secondarySalesRep) )? salesRepUserIds.get(wq.secondarySalesRep).Id : null;
            inQuote.Ordered_by__c = findOrCreateContactForQuote().Id;
            inQuote.CurrencyISOCode = inQuote.CurrencyIsoCode__c;
            inQuote = setEarliestDeliveryDateIfNull(inQuote);
            upsert inQuote Rentalman_Quote_Id__c;
            
            if(!productsSkuMap.isEmpty()){
                //Add, Update or Delete line items
                processLineItems();
            }  
            if(inQuote.Delivery_Charge__c != null || inQuote.Pickup_Charge__c !=null) {  
                upsert inQuote Rentalman_Quote_Id__c; //update again because in process line items
            }
        }
        return inQuote.Id;
    }

    private void processLineItems() {
        List<SBQQ__QuoteLine__c> linesToDelete = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLinesLst = new List<SBQQ__QuoteLine__c>();
        Map<String, SBQQ__QuoteLine__c> linesToUpsert = new Map<String,SBQQ__QuoteLine__c> ();

        if(!wq.linedata.isEmpty()) {
            for(QuoteLineRequestWrapper lineData: wq.linedata){
                SBQQ__QuoteLine__c line = lineData.data;
                line.SBQQ__Quote__c = inQuote.Id;
                line.Line_Composite_Key__c = getCompositeKey(line.Global_Line_Number__c);
                System.debug('\n @@ composite key for linedata =' + line.Line_Composite_Key__c);
                //SAL-25998
                if(lineData.productSKU == '0000000') {
                    if(line.Misc_Charges_Type__c == DELIVERY || line.Misc_Charges_Type__c == 'DEL') {
                        line.Misc_Charges_Type__c = DELIVERY;
                        lineData.productSKU = delPickUpProdSKUMap !=null && delPickUpProdSKUMap.containsKey(line.Misc_Charges_Type__c) ? delPickUpProdSKUMap.get(line.Misc_Charges_Type__c):genericProductSku;
                        inQuote.Delivery_Charge__c = line.Misc_Charge__c;
                    }
                    if(line.Misc_Charges_Type__c == PICKUP ) {
                        lineData.productSKU = delPickUpProdSKUMap !=null && delPickUpProdSKUMap.containsKey(line.Misc_Charges_Type__c) ? delPickUpProdSKUMap.get(line.Misc_Charges_Type__c):genericProductSku;
                        inQuote.Pickup_Charge__c = line.Misc_Charge__c;
                    }
                }
                line.SBQQ__Product__c = productsSkuMap.containsKey(lineData.productSKU) ? productsSkuMap.get(lineData.productSKU).Id : null;
                line.SBQQ__PricebookEntryId__c = priceBookEntries.containsKey(lineData.productSKU) ? priceBookEntries.get(lineData.productSKU).Id : null;
                if(line.SBQQ__Product__c == null) {
                    line.SBQQ__Product__c = prodToItemNotFoundMap.get(companyCode).Id;
                    //throw new QuoteException ('Product ' + lineData.productSKU +  ' not found!');
                }
                if(line.SBQQ__PricebookEntryId__c == null) {throw new QuoteException ('PriceBookEntry not found for Product '+ lineData.productSKU + ' !');}
                
                if(hasProductOnTheLineChanged(line)) {
                    linesToDelete.add(sfLines.get(line.Line_Composite_Key__c));
                }
                //SAL-23899
                getExistingMatchingSFLines(line);
                if (!lineItemExistsMap.isEmpty() && lineItemExistsMap.containsKey(String.valueOf(line.Global_Line_Number__c))){
                    SBQQ__QuoteLine__c quoteIemRecToDelete = lineItemExistsMap.get(String.valueOf(line.Global_Line_Number__c));
                    
                    line.Total_Price__c = quoteIemRecToDelete?.Total_Price__c;
                    line.Line_Item_Type__c = quoteIemRecToDelete?.Line_Item_Type__c;
                    line.Rates_Branch__c = quoteIemRecToDelete?.Rates_Branch__c;
                    if(!linesToDelete.contains(quoteIemRecToDelete)){
                        linesToDelete.add(quoteIemRecToDelete);
                    }
                }
                line.SBQQ__Product__c = productsSkuMap.get(lineData.productSKU).Id;
                linesToUpsert.put(line.Line_Composite_Key__c, line);
            }
        }

        if(globalLineNumbersToDelete != null) {
            for(Integer globalLineNum : globalLineNumbersToDelete) {
                String lineCompositeKey = getCompositeKey(globalLineNum);
                if(sfLines.containsKey(lineCompositeKey)) {
                    linesToDelete.add(sfLines.get(lineCompositeKey));
                }
            }
        }
        
        //DO NOT CHANGE the order of these DML operations.
        delete linesToDelete; //first delete the lines
        
        List<SBQQ__QuoteLine__c> linesToUpsertList= linesToUpsert.values();
        upsert linesToUpsertList Line_Composite_Key__c;
    }

    private static String companyCode {
        get {
            if(wq.companyCodeId != null) {
                System.debug('\n @@ - co code - ' + wq.companyCodeId);
                return wq.companyCodeId;
            }
            throw new QuoteException('Company Code is required!');
        }
        set;
    }

    private static String rentalmanQuoteId {
        get {
            if(wq.data.Rentalman_Quote_Id__c != null) {
                return companyCode + '-' + wq.data.Rentalman_Quote_Id__c;
            }
            throw new QuoteException('Rentalman Quote Id is required!');
        }
        set;
    }

    private static Account relAcct {
        get{
            if (relAcct == null && wq!=null && String.isNotBlank(wq.rmAccountNumber)) {   
                //if it's a new Quote or Account has changed for the existing Quote, query for the AccountId
                if(isNew || (isNew == false && hasAccountChanged)) {
                    String uniqueRMAccountNumber = wq.companyCodeId + '-' +  wq.rmAccountNumber;
                    List<Account> acct =  new List<Account>();
                    acct = SBR_3_0_QuoteDA.getRelatedAccount(uniqueRMAccountNumber);
                    if(acct.size() > 0 ) {
                        System.debug('\n @@  + relAcct =' + acct);
                        return acct[0];
                    }
                }
                else {
                    List<Account> acct =  new List<Account>();
                    acct = SBR_3_0_QuoteDA.getRelatedAccountId(sfQuote.SBQQ__Account__c);
                    return acct[0];
                }
                throw new QuoteException('Related Account not found!');
            }
            return relAcct;
        }
    }

    private static SBQQ__Quote__c sfQuote {
        get{
            if(sfQuote == null) {
                List<SBQQ__Quote__c> quoteRecord = new List<SBQQ__Quote__c>();
                quoteRecord = SBR_3_0_QuoteDA.getQuoteByRentalmanQuoteId(rentalmanQuoteId);
                if(quoteRecord.size() > 0 ) {                   
                    sfQuote = quoteRecord[0];
                    if(sfQuote.SBQQ__Account__r.RM_Account_Number_Display__c != wq.rmAccountNumber) { hasAccountChanged =true; }
                    if(sfQuote.Branch__r.Branch_Location_Number__c != wq.branchNumber) { hasBranchChanged = true; }
                    if(String.isNotBlank(sfQuote.Jobsite__r.Job_Site_Id__c) && sfQuote.Jobsite__r.Job_Site_Id__c != wq.jobSiteId) { 
                        hasJobSiteChanged = true; 
                    }
                    if(sfQuote.SBQQ__SalesRep__c != null && sfQuote.SBQQ__SalesRep__r.RepID__c != wq.primarySalesRep ){
                        hasPrimarySaleRepChanged = true ;
                    }
                    if(sfQuote.Secondary_Rep__c != null && wq.secondarySalesRep != null && sfQuote.Secondary_Rep__r.RepID__c != wq.secondarySalesRep){
                        hasSecSaleRepChanged = true ;
                     }
                    return sfQuote;
                }
                else {
                    isNew = true; //no existing SF record found
                }
            }
            System.debug('\n @@ isNew =' + isNew);
            return sfQuote;
        }
        set;
    }

    private static Map<String, SBQQ__QuoteLine__c> sfLines {
        get {
            if(sfLines == null && sfQuote != null) {                
                /// update to fetch by quote#
                sfLines = SBR_3_0_QuoteLineDA.getQuoteLinesMap(sfQuote.Id);
            }
            return sfLines;
        }
        set;
    }

    private static AssociatedLocation jobSite {
        get{        
            if(
                jobSite == null && wq != null && String.isNotBlank(wq.jobSiteId) &&
                (isNew || (!isNew && hasJobSiteChanged))
            ) {
                List<AssociatedLocation> jobsites = SBR_3_0_JobsiteDA.getJobSitesByJobSiteId(wq.jobSiteId);
                if(!jobsites.isEmpty()){
                    System.debug('\n @@ jobsite = ' + jobsites[0]);
                    jobSite = jobsites[0];
                    return jobSite; 
                }
                else {
                    throw new QuoteException('Jobsite Id ' + wq.jobSiteId + ' does not exist in SF!');
                }
            }
            else if(jobSite == null && sfQuote != null && sfQuote.Jobsite__r != null ) {
                return sfQuote.Jobsite__r;
            }
            return jobSite;
        }
        set;
    }

    private static String branchId {
        get {
            if(branchId == null && String.isNotBlank(wq.branchNumber)) {
                if(isNew || (!isNew && hasBranchChanged)) {
                    Map<String,Schema.Location> branches = SBR_3_0_BranchDA.getBranchByNumbers(new Set<String> {wq.branchNumber});
                    if(branches.containsKey(wq.branchNumber)) {
                        if(branches.get(wq.branchNumber).Time_Zone__c !=null){
                            branchTimeZoneOffset = String.ValueOf(branches.get(wq.branchNumber).Time_Zone__c);
                        }                    
                        System.debug('\n @@ branch id ' + branches.get(wq.branchNumber).Id );
                        return branches.get(wq.branchNumber).Id;
                    }
                }
                else {
                    return sfQuote.Branch__c;
                }
                throw new QuoteException('Branch ' + wq.branchNumber + ' not found!');
            }
            return branchId;
        }
        set;
    }
        
    private static Map<String,User> salesRepUserIds {
        get{
            if(salesRepUserIds == null) {
                Set<String> reps = new Set<String>();
                if(String.isNotBlank(wq.primarySalesRep)){ 
                    reps.add(wq.primarySalesRep);
                }
                if(String.isNotBlank(wq.secondarySalesRep)){
                    reps.add(wq.secondarySalesRep);
                }
                salesRepUserIds = SBR_3_0_UserDA.getUserMapBySalesRepIds(reps);
                if(!salesRepUserIds.isEmpty()) {
                    return salesRepUserIds;
                }
                //25663, removing this exception
                //throw new QuoteException('Related Sales Rep not found!');
            }
            return salesRepUserIds;
        }
        set;
    }

    private static Map<String,Id> rtMap {
        get {
            if(String.isBlank(wq.type)) {
                throw new QuoteException ('Type of Quote is required!');
            }
            if(rtMap == null) {
                rtMap = new Map<String,Id>();
                
                Map<String,Id> quoteRecTypeMap = SBR_3_0_RecordTypesForObject.getRecordTypeDevNameToIds(SOBJECT_QUOTE);
                
                for(String recTypeDevName : quoteRecTypeMap.keyset()){
                    if(recTypeDevName == wq.type){
                        rtMap.put(wq.type, quoteRecTypeMap.get(recTypeDevName));
                    }
                }
                return rtMap;
            }
            return rtMap;
        }
        set;
    }

    private static Map<String, Product2> prodToItemNotFoundMap {
        get {
            if(prodToItemNotFoundMap == null) {                
                    /// update to fetch by contract#
                    prodToItemNotFoundMap = SBR_3_0_ProductDA.getGenericProductForEachCompanyCodes();
            }
            return prodToItemNotFoundMap;
        }
        set;
    }
    @TestVisible
    // SAL-25998
    private static Map<String, String> delPickUpProdSKUMap {
        get {
            if(delPickUpProdSKUMap == null) {   
             delPickUpProdSKUMap = new Map<String, String>();     
                Map<String, Product2> prodToDelPickupMap = SBR_3_0_ProductDA.getDeliveryPickupProds();
                for(Product2 delProd : prodToDelPickupMap.values()){
                    if(delProd.Company_Code__c == companyCode ){
                        delPickUpProdSKUMap.put(delProd.Item_Number__c,delProd.Product_SKU__c);
                    }
                } 
            }
            return delPickUpProdSKUMap;
        }
        set;
    }

    private static Set<String> productSkus {
        get {
            Set<String> skus =  new Set<String>();
            if(productSkus == null) {
                //Get Generic Product info
                if(prodToItemNotFoundMap != null && prodToItemNotFoundMap.containsKey(companyCode)) {
                    Product2 genericProduct= prodToItemNotFoundMap.get(companyCode);
                    skus.add(genericProduct.Product_SKU__c);
                    genericProductSku = genericProduct.Product_SKU__c;
                }
                if(delPickUpProdSKUMap != null) {
                    skus.addAll(delPickUpProdSKUMap.values());
                }
                for(QuoteLineRequestWrapper lineitem: wq.linedata){
                    if(String.isNotBlank(lineitem.productSKU)){
                        skus.add(lineitem.productSKU);
                    }
                }
                if(!skus.isEmpty()) {
                    System.debug('\n @@ skus s = ' + skus);
                    return skus;
                }
                throw new QuoteException('Products SKUs not found in the request!');
            }
            return skus;
        }
        set;
    }

    private static Map<String,Product2> productsSkuMap {
        get {
            if(!productSkus.isEmpty() && productsSkuMap == null) {
                Map<String,Product2> skuMap = new Map<String, Product2> ();
                productsSkuMap = SBR_3_0_ProductDA.getProductByExternalId(productSkus);
                if(productsSkuMap!=null && !productsSkuMap.isEmpty()) {
                    return productsSkuMap;
                }
                throw new QuoteException('No Products found!');
            }
            return productsSkuMap;
        }
        set;
    }

    private static Map<String, PricebookEntry> priceBookEntries {
        get {
            if(!productSkus.isEmpty() && priceBookEntries == null) {
                Set<String> prodSkusForPriceBookEntry = new Set<String>();
                prodSkusForPriceBookEntry.addAll(productSkus);
                System.debug('\n @@ prodSkusForPriceBookEntry = '+ prodSkusForPriceBookEntry);
                priceBookEntries = SBR_3_0_UtilityDA.getPriceBookEntriesByProductSKUs(prodSkusForPriceBookEntry, companyCode);
                if(priceBookEntries!=null && !priceBookEntries.isEmpty()) {
                    return priceBookEntries;
                }
                throw new QuoteException('No Price Book Entries found!');
            }
            return priceBookEntries;
        }
        set;
    }

    private static Schema.Location jobLocation {
        get{
            if (jobLocation == null && wq.address != null && SBR_3_0_SalesHelper.isAddressComplete(wq.address)) {
                Schema.Location loc = SBR_3_0_JobsiteDA.getRelatedJobLocation(wq.address);
                if(loc != null) {
                    return loc;
                }
                return setNewJobLocation();
            }
            if (jobLocation == null && SBR_3_0_SalesHelper.isAddressComplete(relAcct)) {
                SBR_3_0_WrapAddress acctAddr = SBR_3_0_SalesHelper.WrapAccountShippingAddress(relAcct);
                Schema.Location loc = SBR_3_0_JobsiteDA.getRelatedJobLocation(acctAddr);
                if(loc != null) {
                    return loc;
                }
                return setNewJobLocation();
            }
            return jobLocation;
        }
        set;
    }

    public AssociatedLocation createJobSite(SBQQ__Quote__c req){
        AssociatedLocation js = new AssociatedLocation();
        //address field
        if(wq.address != null) {
            js = SBR_3_0_SalesHelper.createJoSiteFromAddress(wq.address, relAcct.Id, jobLocation.Id, branchId);
        } 
        else {
            js = SBR_3_0_SalesHelper.createJoSiteFromShippingAddr(relAcct, jobLocation.Id, branchId);
        }
        js.SalesRepUserId__c = salesRepUserIds.get(wq.primarySalesRep).Id;
        insert js;
        return js;
    }
        
    private static Schema.Location setNewJobLocation() {
        Schema.Location l = new Schema.Location();
        l.Company_Code__c = companyCode;
        if(wq.address != null) {
            l = SBR_3_0_SalesHelper.createJobLocFromAddress(wq.address);
        }
        else {
            l = SBR_3_0_SalesHelper.createJobLocFromShippingAddr(relAcct);
        }
        if (wq.orderedBy != null) {
            if (String.isNotBlank(wq.orderedBy.firstName) && String.isNotBlank(wq.orderedBy.lastName)) {
                l.Name = wq.orderedBy.firstName.trim() + ' ' + wq.orderedBy.lastName.trim();
            }
        }
        insert l;
        return l;
    }

    private String getCompositeKey(Decimal globalLineNum) {
        if(globalLineNum == null) {throw new QuoteException ('Global Line Number is required!');}
        return rentalmanQuoteId + '-' + Integer.valueOf(globalLineNum);
    }

    private Boolean hasProductOnTheLineChanged(SBQQ__QuoteLine__c inbound) {
        if(
            inbound.SBQQ__PricebookEntryId__c != null
            && sfLines != null
            && sfLines.containsKey(inbound.Line_Composite_Key__c)
            && sfLines.get(inbound.Line_Composite_Key__c).SBQQ__PricebookEntryId__c != inbound.SBQQ__PricebookEntryId__c
        ) {
            return true;
        }
        return false;
    }
    //SAL-23899
    private void getExistingMatchingSFLines(SBQQ__QuoteLine__c inbound) {
        if(sfLines != null) {
            for(SBQQ__QuoteLine__c sfLine : sfLines.values()){
                if(sfLine.Global_Line_Number__c!=null && (sfLine.Global_Line_Number__c == inbound.Global_Line_Number__c)){
                    lineItemExistsMap.put(String.valueOf(inbound.Global_Line_Number__c),sfLine);
                }   
            }
        }
    }

    private SBQQ__Quote__c setAddress(SBQQ__Quote__c q) {
        if(wq.address != null && SBR_3_0_SalesHelper.isAddressComplete(wq.address)) {
            q.SBQQ__ShippingStreet__c = wq.address.street1;
            q.SBQQ__ShippingCity__c = wq.address.city;
            q.SBQQ__ShippingCountry__c = wq.address.country;
            q.SBQQ__ShippingPostalCode__c = wq.address.zip;
        }
        return q;
    }

    private SBQQ__Quote__c setEarliestDeliveryDateIfNull(SBQQ__Quote__c q) {
        Map<String, Object> quotePopulatedFields = q.getPopulatedFieldsAsMap();
        if(quotePopulatedFields.containsKey(START_DATE_FIELD) && quotePopulatedFields.get(START_DATE_FIELD) <> NULL){
            if((quotePopulatedFields.containsKey(DELIVERY_DATE_FIELD) && quotePopulatedFields.get(DELIVERY_DATE_FIELD) == NULL) || 
            !quotePopulatedFields.containsKey(DELIVERY_DATE_FIELD)){
                q.put(DELIVERY_DATE_FIELD, quotePopulatedFields.get(START_DATE_FIELD));
            }
        }
        return q;
    }

    private Contact findOrCreateContactForQuote() {
        Contact c = new Contact();
        if (wq.orderedBy != null) {
            c = SBR_3_0_SalesHelper.findOrCreateContact(wq.orderedBy, wq.address, relAcct);
        }
        return c;
    }

    private SBQQ__Quote__c setShipToContact(SBQQ__Quote__c q) {
        if(wq.shipTo != null && String.isNotBlank(wq.shipTo.firstName) && String.isNotBlank(wq.shipTo.lastName)) {
            q.SBQQ__ShippingName__c = wq.shipTo.firstName.trim() + ' ' + wq.shipTo.lastName.trim();
        }
        return q;
    }

    private void setDeletedLineData(String req) {
        globalLineNumbersToDelete = new Set<Integer>();
        JSONParser parser = JSON.createParser(req);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME)  {
                parser.nextValue();
                if (parser.getCurrentName() == 'deletedLineData') { // deletedLineData
                    while(parser.nextToken() != JSONToken.END_ARRAY) {
                        if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                            parser.nextValue();
                            System.debug('\n $$2 ' + parser.getCurrentName());
                            if(parser.getCurrentName() == 'Global_Line_Number__c'){ // global_line__c
                                globalLineNumbersToDelete.add(parser.getIntegerValue());
                            }
                        }
                        else if(parser.getCurrentToken() == JSONToken.END_OBJECT) {
                            continue;
                        } else if (parser.getCurrentToken() == JSONToken.START_OBJECT) {
                            continue;
                        }
                    }
                    break;
                }
            }
        }
    }

    public class QuoteRequestWrapper {
        public String rmAccountNumber {get; set;}
        public String branchNumber {get; set;}
        public String jobSiteId {get; set;}
        public String type {get; set;}
        public String companyCodeId {get; set; }
        public String primarySalesRep {get; set;}
        public String secondarySalesRep {get; set;}
        public SBR_3_0_ContactWrap orderedBy = new SBR_3_0_ContactWrap();
        public SBR_3_0_ContactWrap shipTo = new SBR_3_0_ContactWrap();
        public SBR_3_0_WrapAddress address = new SBR_3_0_WrapAddress(); 
        public SBQQ__Quote__c data {get; set;}
        public List<QuoteLineRequestWrapper> linedata {get; set;}
    }

    public class QuoteLineRequestWrapper {
        public String productSKU {get; set;}
        public SBQQ__QuoteLine__c data {get; set;}
    }

    public class QuoteException extends Exception {}
}