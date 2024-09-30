/*********************************************************************************************************************
* Apex Class: P2P_CustomCreateQuote
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Helper class for creating Quote request passed from .COM to Salesforce using rest API in P2P_API_Web_Quote
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION     DEVELOPER NAME          DATE                DETAIL FEATURES
    1.0         Delvin Riley			2023-10-12			Initial version    
*********************************************************************************************************************/

public with sharing class P2P_CustomCreateQuote {
    //set request quote wrapper with request payload
    private static QuoteRequestWrapper wq = new QuoteRequestWrapper();
    //variable used to refer to the quote that will be upserted to Salesforce
    private static SBQQ__Quote__c quoteToUpsert;  
    // variable to store existing quote if one exist
    private static SBQQ__Quote__c existing;
    // variable to store existing quote line items
    private static List<SBQQ__QuoteLine__c> returnLines;
    // variable to store quote to return
    private Static Database.UpsertResult returnQuote;
    //variable determines if quote is net new to Salesforce
    private static Boolean isNew = false;
    //variable determines the api name for the call to create quotes in Rentalman from SF
    private static final String APINAME = 'Create_Quotes_API';    
    private static Boolean staleInboundOrder = false;
    //variable determines if the Account associated with the quote has changed
    private static Boolean hasAccountChanged = false;
    //variable determines if the Jobsite associated with the quote has changed
    private static Boolean hasJobSiteChanged = false;
    //variable determines if the Branch associated with the quote has changed
    private static Boolean hasBranchChanged = false;
    //variable determines if the Primary Sales Rep associated with the quote has changed
    private static Boolean hasPrimarySaleRepChanged = false;
    //variable determines if the Secondary Sales Rep associated with the quote has changed
    private static Boolean hasSecSaleRepChanged = false;
    private static String branchTimeZoneOffset;
    private static String genericProductSku = 'x';
    private static final String SOBJECT_QUOTE = 'SBQQ__Quote__c';
    private static final String DELIVERY = 'DELIVERY';
    private static final String PICKUP = 'PICKUP';
    private static List<String> globalLineNumbersToDelete;
    //map that contains the line items that exists associated with the quote
    private Map<String,SBQQ__QuoteLine__c> lineItemExistsMap = new Map<String,SBQQ__QuoteLine__c>();//SAL-23899
    
    // method that sets and deserializes the request payload
    public P2P_CustomCreateQuote(String req) {
       
        system.debug('p2p P2P_CustomCreateQuote start ' + system.now());
        
        //deserialize request and set variables
        wq = (QuoteRequestWrapper)JSON.deserialize(req, QuoteRequestWrapper.class);
        //create quote object with the data node from the request payload
        quoteToUpsert = (SBQQ__Quote__c)JSON.deserialize(JSON.serialize(wq.data), SBQQ__Quote__c.class);
       
        //check if the request contains deleted line data and set
       
        if(req.contains('deletedLineData')) {
            setDeletedLineData(req);
        }
        
        
                system.debug('p2p P2P_CustomCreateQuote end ' + system.now());

      
    }
    
    //method to upsert Quote to Salesforce
    public SBQQ__Quote__c upsertQuoteToSF() {
        //transmit quote
              system.debug('p2p upsertQuoteToSF start ' + system.now());

        
        //set existing variable to sfQuote method which returns a quote if one exist in the system
        existing = sfQuote;
        Account relatedAccount = relAcct;
        
        schema.Location jobLoc = jobLocation;
      
        
        
        //set attributes on the quote to upsert
     
        //quoteToUpsert.Submitted_to_Wynne__c = false;
        quoteToUpsert.SBQQ__Account__c = relatedAccount.Id;
        system.debug('delvin ' + quoteToUpsert.Branch__c );
        quoteToUpsert.Branch__c = branchId;
        system.debug('delvin ' + quoteToUpsert.Branch__c );
        //account record type text quick fix
        quoteToUpsert.Account_Record_Type_Txt__c = relatedAccount.Record_Type_Text__c;
       
        //ADDed the if condition need to check 
        if(quoteToUpsert.CurrencyIsoCode__c!=null){
            quoteToUpsert.CurrencyISOCode = quoteToUpsert.CurrencyIsoCode__c;
        }
        // END
     
        //if the jobsite is not empty then set variable to the jobsite id/else create a jobsite and set to created jobsite id
       
        quoteToUpsert.Jobsite__c = (jobSite != null) ? jobSite.Id : createJobSite(quoteToUpsert, relatedAccount, jobLoc).Id; //assign jobsiteId or create one
       
        //if the type field from the payload is not black then get record type and set else set to null
        quoteToUpsert.RecordTypeId = (String.isNotBlank(wq.type)) ? rtMap.get(wq.type) : null;
        //set owner id to integration user or created by user? salesrep will not own
        List<User> user = [SELECT Id FROM User WHERE Name = :wq.ownerName LIMIT 1];
        if (!user.isEmpty()) quoteToUpsert.OwnerId = user[0].Id;
        if (wq.orderedBy != null) {
        quoteToUpsert.Ordered_by__c = findOrCreateContactForQuote(relatedAccount).Id;
        }
        
        //database upsert used to upsert quote based on Salesforce GUID match
        returnQuote = Database.upsert(quoteToUpsert) ;
      
        
        
        
        if(!productsSkuMap.isEmpty()){
            //Add, Update or Delete line items
            punchoutProcessLineItems();
        }        

      
        //delvin commenting for test
       // if(quoteToUpsert.Delivery_Charge__c != null || quoteToUpsert.Pickup_Charge__c !=null) {  
        //    returnQuote = Database.upsert(quoteToUpsert); //update again because in process line items
            
        //}
     
         existing = SBR_3_0_QuoteDA.punchoutGetQuoteResponse(returnQuote.Id);
      
        
        
        system.debug('delvin ' + existing.Branch__c );
        
      //  returnLines =  SBR_3_0_QuoteLineDA.getQuoteLines(returnQuote.Id);
        
        			
              system.debug('p2p upsertQuoteToSF end ' + system.now());

       // return (existing.Rentalman_Quote_Id__c != null) ? (String)existing.Rentalman_Quote_Id__c : (String)existing.Name;    
        return existing;
    }
    
   

    
   private void punchoutProcessLineItems(){
       
                     system.debug('p2p punchoutProcessLineItems start ' + system.now());

      
        List<SBQQ__QuoteLine__c> linesToDelete = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> quoteLinesLst = new List<SBQQ__QuoteLine__c>();
        List<SBQQ__QuoteLine__c> linesToUpsert = new List<SBQQ__QuoteLine__c> ();

        if(!wq.linedata.isEmpty()) {
            for(QuoteLineRequestWrapper lineData: wq.linedata){
                SBQQ__QuoteLine__c line = lineData.data;
                if(linedata.data.Id == null)
                {
                    line.SBQQ__Quote__c = quoteToUpsert.Id;
                }
                
                //logic for P2P exclusion of global line numbers for initial create of punchout quote
               
                    //line.Line_Composite_Key__c = getCompositeKey(line.Global_Line_Number__c);
             
                
                //SAL-25998 delvin commenting for p2p test
                if(lineData.productSKU == '0000000') {
                    if(line.Misc_Charges_Type__c == DELIVERY || line.Misc_Charges_Type__c == 'DEL') {
                        line.Misc_Charges_Type__c = DELIVERY;
                        lineData.productSKU = delPickUpProdSKUMap !=null && delPickUpProdSKUMap.containsKey(line.Misc_Charges_Type__c) ? delPickUpProdSKUMap.get(line.Misc_Charges_Type__c):genericProductSku;
                        quoteToUpsert.Delivery_Charge__c = line.Misc_Charge__c;
                    }
                    if(line.Misc_Charges_Type__c == PICKUP ) {
                        lineData.productSKU = delPickUpProdSKUMap !=null && delPickUpProdSKUMap.containsKey(line.Misc_Charges_Type__c) ? delPickUpProdSKUMap.get(line.Misc_Charges_Type__c):genericProductSku;
                        quoteToUpsert.Pickup_Charge__c = line.Misc_Charge__c;
                    }
                }
                line.SBQQ__Product__c = productsSkuMap.containsKey(lineData.productSKU) ? productsSkuMap.get(lineData.productSKU).Id : null;
                //TODO: LOOK INTO
              
                line.SBQQ__PricebookEntryId__c = priceBookEntries.containsKey(lineData.productSKU) ? priceBookEntries.get(lineData.productSKU).Id : null;
              
                if(line.SBQQ__Product__c == null) {
                   
                    //line.SBQQ__Product__c = prodToItemNotFoundMap.get(companyCode).Id;
                    throw new QuoteException ('Product ' + lineData.productSKU +  ' not found!');
                }
                if(line.SBQQ__PricebookEntryId__c == null) {throw new QuoteException ('PriceBookEntry not found for Product '+ lineData.productSKU + ' !');}
                
                if(punchoutHasProductOnTheLineChanged(line)) {
                    linesToDelete.add(sfLines.get(line.Id));
                }
                //SAL-23899
                
                punchoutGetExistingMatchingSFLines(line);
                if (!lineItemExistsMap.isEmpty() && lineItemExistsMap.containsKey(String.valueOf(line.Id))){
                    SBQQ__QuoteLine__c quoteIemRecToDelete = lineItemExistsMap.get(String.valueOf(line.Id));
                    
                    line.Total_Price__c = quoteIemRecToDelete?.Total_Price__c;
                    line.Line_Item_Type__c = quoteIemRecToDelete?.Line_Item_Type__c;

                    if(!linesToDelete.contains(quoteIemRecToDelete)){
                        linesToDelete.add(quoteIemRecToDelete);
                    }
                }
                line.SBQQ__Product__c = productsSkuMap.get(lineData.productSKU).Id;
                
                linesToUpsert.add(line);
            }
        }

        if(globalLineNumbersToDelete != null) {
            for(String globalLineNum : globalLineNumbersToDelete) {
               
                SBQQ__QuoteLine__c lineCompositeKey = SBR_3_0_QuoteLineDA.getQuoteLine(String.valueOf(globalLineNum));
                if(lineCompositeKey != null) {
                    linesToDelete.add(lineCompositeKey);
                }
            }
        }

        //DO NOT CHANGE the order of these DML operations.
    
        delete linesToDelete; //first delete the lines
      

      //  List<SBQQ__QuoteLine__c> linesToUpsertList= linesToUpsert.values();

        Database.upsert(linesToUpsert);
		
                            system.debug('p2p punchoutProcessLineItems end ' + system.now());

       
    }
    
    
    private static String companyCode {
        get {
          
            if(wq.companyCodeId != null) {
                       

                return wq.companyCodeId;
            }
            throw new QuoteException('Company Code is required!');
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
            
            SBQQ__Quote__c quoteRecord = new SBQQ__Quote__c();
            //P2P handle to get quote by SF ID
            if(wq.Id != null)
            {
                quoteRecord = SBR_3_0_QuoteDA.punchoutGetQuote(wq.Id);
            }
            
            if(quoteRecord.Id != null) {  
                sfQuote = quoteRecord;
                if(sfQuote.SBQQ__Account__r.RM_Account_Number_Display__c != wq.rmAccountNumber) { hasAccountChanged =true; }
                if(sfQuote.Branch__r.Branch_Location_Number__c != wq.branchNumber) { hasBranchChanged = true; }
                if(String.isNotBlank(sfQuote.Jobsite__r.Job_Site_Id__c) && sfQuote.Jobsite__r.Job_Site_Id__c != wq.jobSiteId) { 
                    hasJobSiteChanged = true; 
                }
                //if(sfQuote.SBQQ__SalesRep__c != null && sfQuote.SBQQ__SalesRep__r.RepID__c != wq.primarySalesRep ){
                //   hasPrimarySaleRepChanged = true ;
                // }
                //  if(sfQuote.Secondary_Rep__c != null && wq.secondarySalesRep != null && sfQuote.Secondary_Rep__r.RepID__c != wq.secondarySalesRep){
                //     hasSecSaleRepChanged = true ;
                //  }
                return sfQuote;
            }
            else {
                isNew = true; //no existing SF record found
            }
            
          
            return sfQuote;
        }
        set;
    }
    
    private static Map<String, SBQQ__QuoteLine__c> sfLines {
        get {
            if(sfLines == null && sfQuote != null) { 
                
                sfLines = SBR_3_0_QuoteLineDA.punchoutGetQuoteLinesMap(sfQuote.Id);
                
                
                
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
                    system.debug('delvin ' + wq.branchNumber );
                    Map<String,Schema.Location> branches = SBR_3_0_BranchDA.getBranchByNumbers(new Set<String> {wq.branchNumber});
                    system.debug('delvin ' + branches);
                    if(branches.containsKey(wq.branchNumber)) {
                        if(branches.get(wq.branchNumber).Time_Zone__c !=null){
                            branchTimeZoneOffset = String.ValueOf(branches.get(wq.branchNumber).Time_Zone__c);
                        }              
                                system.debug('delvin ' + branches.get(wq.branchNumber).Id );

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
    
    public AssociatedLocation createJobSite(SBQQ__Quote__c req, Account relatedAccount, Schema.Location jobLoc){
        AssociatedLocation js = new AssociatedLocation();
        //address field
        if(wq.address != null) {
            js = SBR_3_0_SalesHelper.createJoSiteFromAddress(wq.address, relatedAccount.Id, jobLoc.Id, req.Branch__c);
        } 
        else {
            js = SBR_3_0_SalesHelper.createJoSiteFromShippingAddr(relatedAccount, jobLoc.Id, req.Branch__c);
        }
        //Added P2P Logic to set user id to integration user
        
        List<User> user = [SELECT Id FROM User WHERE Name = :wq.ownerName LIMIT 1];
        if (!user.isEmpty())   js.SalesRepUserId__c = user[0].Id;
        
        
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
    
   // private String getCompositeKey(Decimal globalLineNum) {
   //     if(globalLineNum == null) {throw new QuoteException ('Global Line Number is required!');}
   //     return rentalmanQuoteId + '-' + Integer.valueOf(globalLineNum);
    //}
    
    //created method for punchout handling
    private Boolean punchoutHasProductOnTheLineChanged(SBQQ__QuoteLine__c inbound){
        if(
            inbound.SBQQ__PricebookEntryId__c != null 
            && sfLines != null 
            && sfLines.containsKey(inbound.Id)
            && sfLines.get(inbound.Id).SBQQ__PricebookEntryId__c != inbound.SBQQ__PricebookEntryId__c
        ) {
            return true;
        }
        return false;
        
    }
    
  
    //P2P HANDLING TO EXCLUDE GLOBAL LINE NUMBER FOR P2P
    private void punchoutGetExistingMatchingSFLines(SBQQ__QuoteLine__c inbound){
        
        if (sfLines != null){
            for(SBQQ__QuoteLine__c sfLine : sfLines.values()){
                if(sfLine.Id!=null && (sfLine.Id == inbound.Id)){
                    lineItemExistsMap.put(String.valueOf(inbound.Id),sfLine);
                }   
                
            }
            
        }
        
    }
	@TestVisible
    private SBQQ__Quote__c setAddress(SBQQ__Quote__c q) {
       if(wq.address != null && SBR_3_0_SalesHelper.isAddressComplete(wq.address)) {
            q.SBQQ__ShippingStreet__c = wq.address.street1;
            q.SBQQ__ShippingCity__c = wq.address.city;
            q.SBQQ__ShippingCountry__c = wq.address.country;
            q.SBQQ__ShippingPostalCode__c = wq.address.zip;
        }
        return q;
    }
    
    private Contact findOrCreateContactForQuote(Account relatedAccount) {
        Contact c = new Contact();
        c = SBR_3_0_SalesHelper.p2pFindOrCreateContact(wq.orderedBy, wq.address, relatedAccount);
        return c;
    }
    
  
    @TestVisible
    private void setDeletedLineData(String req) {
         globalLineNumbersToDelete = new List<String>();
        JSONParser parser = JSON.createParser(req);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME)  {
                parser.nextValue();
                if (parser.getCurrentName() == 'deletedLineData') { // deletedLineData
                    while(parser.nextToken() != JSONToken.END_ARRAY) {
                        if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                            parser.nextValue();
                            if(parser.getCurrentName() == 'Id'){ // id for p2p process
                                globalLineNumbersToDelete.add(parser.getText());
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
       
        public string Id {get; set;} //added by Delvin P2P
        
        public String rmAccountNumber {get; set;}
        public String branchNumber {get; set;}
        public String jobSiteId {get; set;}
        public String type {get; set;}
        //add ownerId for P2P?
        public string ownerName {get; set;}
        public String companyCodeId {get; set; }
        public String primarySalesRep {get; set;}
        public String secondarySalesRep {get; set;}
        public String initiateTransmit {get; set;} // Added by Ishan for P2P
        public string name {get; set;}
        
        public SBR_3_0_ContactWrap orderedBy = new SBR_3_0_ContactWrap();
        public SBR_3_0_ContactWrap shipTo = new SBR_3_0_ContactWrap();
        public SBR_3_0_WrapAddress address = new SBR_3_0_WrapAddress(); 
        public SBQQ__Quote__c data {get; set;}
        public List<QuoteLineRequestWrapper> linedata {get; set;}
        //public SBQQ__QuoteLine__c deletedLineData {get; set;}
    }
    
    public class QuoteLineRequestWrapper {
        public String productSKU {get; set;}
        public SBQQ__QuoteLine__c data {get; set;}
        
    }
    
    public class QuoteException extends Exception {}
}