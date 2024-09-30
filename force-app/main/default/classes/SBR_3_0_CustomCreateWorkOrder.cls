/*********************************************************************************************************************
* Apex Class: SBR_3_0_CustomCreateWorkOrder
---------------------------------------------------------------------------------------------------------------------------------------
* Purpose/Methods:
* - Class to containg the logic and wrapper.
---------------------------------------------------------------------------------------------------------------------------------------
* History:
* - VERSION       DATE               DETAIL FEATURES
1.0          2023-02-23          Initial version 
2.0          2023-05-10          Harry Rokad   
**********************************************************************************************************************************************/

public with sharing class SBR_3_0_CustomCreateWorkOrder {
    
    private static WorkOrderRequestWrapper wo = new WorkOrderRequestWrapper();
    private static WorkOrder inWorkOrder; //Inbound WorkOrder details to upsert 
    private static Set<String> linesToDeleteSet  = new Set<String>();
    public static string recordtype;
    
    public SBR_3_0_CustomCreateWorkOrder(String req) {
        wo = (WorkOrderRequestWrapper)JSON.deserialize(req, WorkOrderRequestWrapper.class);
        Map<String, Object> m = (Map<String, Object>) JSON.deserializeUntyped(JSON.serialize(wo.data));
        String jsonStatus = (String)m.get('Status');
        if (jsonStatus != 'Canceled' && jsonStatus !='Closed' && jsonStatus !='D' && jsonStatus !='C'){
            m.remove('Status');
        }
        inWorkOrder = (WorkOrder)JSON.deserialize(JSON.serialize(m), WorkOrder.class);
        if(req.contains('deletedLines')) {
            setDeleteLinesData(req);
        } 
    }
    
    public String syncWorkOrderToSF() {
        String workOrderRecId = loadWorkOrder();
        return workOrderRecId;
    }
    
    private String loadWorkOrder(){
        
        inWorkOrder.SF_PS_RM_WO_Number__c = workOrderNumber;
        if(ownerFind!=null){
            inWorkOrder.OwnerId = ownerFind.Id; 
        }      
        if(relrecordType!=null){
            inWorkOrder.RecordTypeId = relrecordType.Id;
        }
        if(relAcct!=null){
            inWorkOrder.AccountId = relAcct.Id; 
        }
        if(relAsset!=null){
            inWorkOrder.AssetId = relAsset.Id; 
        }
        if(relST!=null){
            inWorkOrder.ServiceTerritoryId = relST.Id;
        }
        if(relSTExpense!=null){
            inWorkOrder.SF_PS_Expense_To_Location__c = relSTExpense.Id;
        }
        if(relUser!=null){
            inWorkOrder.SF_PS_Sales_Rep__c = relUser.Id;
        }
        if(relJobSite!=null){
            inWorkOrder.SF_PS_Job_Site__c = relJobSite.Id;
        }
        if(relServiceResource!=null){
            inWorkOrder.SF_PS_Service_Resource__c = relServiceResource.Id;
        }
        inWorkOrder.CurrencyIsoCode = inWorkOrder.SF_PS_Company_Code__c == '01' ? 'USD' : 'CAD';
        
        if(recordtype == 'SF_PS_Inspection_Record'){
            
            if(!Test.isRunningTest()){
                if(inWorkOrder.Pricebook2Id == null){
                    inWorkOrder.Pricebook2Id=[SELECT id, Name from Pricebook2 where name='Standard Price Book'].id;
                }
            }
            if(relSTExpense!=null){
                inWorkOrder.SF_PS_Expense_To_Location__c = relSTExpense.Id;
            }
            if(relJobSite!=null){
                inWorkOrder.SF_PS_Job_Site__c = relJobSite.Id;
            }
            String qoNos = inWorkOrder.SF_PS_RM_Quote_Num__c;
            if(!String.isBlank(qoNos)){
					List<workorder> quoteWOId=[SELECT id from WorkOrder where SF_PS_RM_WO_Number__c=:inWorkOrder.SF_PS_Company_Code__c+'-'+inWorkOrder.SF_PS_RM_Quote_Num__c];
                    if(quoteWOId.size() > 0){               
                        if(quoteWOId[0].id !=null){
                            inWorkOrder.ParentWorkOrderId=quoteWOId[0].id;
                            WorkOrder updateWO=new WorkOrder(id=quoteWOId[0].id, SF_PS_Is_Converted__c  = true , status='Converted', SF_PS_Order_Status__c='IN');
                            update updateWO;
                            inWorkOrder.SF_PS_RM_Quote_Num__c  = inWorkOrder.SF_PS_Company_Code__c+'-'+inWorkOrder.SF_PS_RM_Quote_Num__c;
                            inWorkOrder.SF_PS_Quote_Num__c  = quoteWOId[0].id;
                        }
                    }
                }
                
            }
        	if(recordtype == 'SF_PS_Credit'){
        
                 String creditNo = inWorkOrder.SF_PS_RM_Credited_WO_Number__c;
                if(!String.isBlank(creditNo)){
                    WorkOrder parentwoId = [SELECT Id,SF_PS_Is_Credited__c,SF_PS_RM_Credited_WO_Number__c,SF_PS_RM_WO_Number__c  FROM WorkOrder WHERE SF_PS_RM_WO_Number__c =:inWorkOrder.SF_PS_Company_Code__c+'-'+creditNo];
                    If(parentwoId!=null){
                        inWorkOrder.ParentWorkOrderId = parentwoId.Id;
                    }
                    parentwoId.SF_PS_Is_Credited__c = true;
                    parentwoId.SF_PS_RM_Credited_WO_Number__c = inWorkOrder.SF_PS_RM_WO_Number__c;
                    system.debug('SF_PS_RM_WO_Number__c' + parentwoId.SF_PS_RM_WO_Number__c);
                    upsert parentwoId SF_PS_RM_WO_Number__c;
                }
        }

        upsert inWorkOrder SF_PS_RM_WO_Number__c;
        
        if(recordtype == 'SF_PS_Inspection_Record'){ 
            if(wo.workOrderLineItem !=null){
                if (!wo.workOrderLineItem.isEmpty()){
                    processLineItems(inWorkOrder.Id, inWorkOrder.eventOrigin__c);
                }
            }
            if(wo.ProductConsumed !=null){
                if(!wo.ProductConsumed.isEmpty()){
                    inWorkOrder.CurrencyIsoCode = inWorkOrder.SF_PS_Company_Code__c == '01' ? 'USD' : 'CAD';
                    processProductConsumed(inWorkOrder.Id,inWorkOrder.eventOrigin__c, inWorkOrder.CurrencyIsoCode, inWorkOrder.Pricebook2Id);
                }
            }
            if(wo.maintenanceSteps !=null){
                if(!wo.maintenanceSteps.isEmpty()){
                    processMaintenanceSteps(inWorkOrder.Id);
                }
            } 
        }
        
        if(recordtype == 'SF_PS_Credit'){
            if(wo.CreditLineItem !=null){
                if(!wo.CreditLineItem.isEmpty()){
                    processCreditLineItem(inWorkOrder.id, inWorkOrder.eventOrigin__c, inWorkOrder.CurrencyIsoCode);
                }
            }
            if(wo.CreditParts !=null){
                if(!wo.CreditParts.isEmpty()){
                    processCreditedParts(inWorkOrder.id, inWorkOrder.eventOrigin__c, inWorkOrder.CurrencyIsoCode);
                }
            }
            
        }
        
        if(recordtype == 'SF_PS_Quote'){
            if(wo.QuoteLineItem !=null){
                if (!wo.QuoteLineItem.isEmpty()){
                    processQuotedLineItems(inWorkOrder.Id, inWorkOrder.eventOrigin__c, inWorkOrder.CurrencyIsoCode);
                }
            }
            if(wo.QuotedParts  !=null){
                if(!wo.QuotedParts.isEmpty()){
                    processQuotedParts(inWorkOrder.Id, inWorkOrder.CurrencyIsoCode);
                }
            }            
        }
        return inWorkOrder.Id;
    }
    
    private void processLineItems(id woId, String eventOrigin){
        List<WorkOrderLineItem> linesToUpsert = new List<WorkOrderLineItem>();
        for (WorkOrderLineItem woli : wo.workOrderLineItem){
            WorkOrderLineItem line = woli;
            line.WorkOrderId = woId;
            if(line.SF_PS_Mechanic_Name__c != null){
                line.SF_PS_Mechanic_Name__c = relServieResourceLineItems(line.SF_PS_Mechanic_Name__c).Id;
            }
            line.SF_PS_WorkOrder_Event_Origin__c  = eventOrigin;
            line.SF_PS_RM_External_Id__c = woli.SF_PS_RM_External_Id__c;
            List<WorkOrderLineItem> CheckForDeletedLines = [SELECT Id,isDeleted FROM Workorderlineitem WHERE SF_PS_RM_External_Id__c =: woli.SF_PS_RM_External_Id__c AND isDeleted = TRUE ALL ROWS];
            if (CheckForDeletedLines.size() == 0){
                linesToUpsert.add(line);
            }
        }
        
        List<WorkOrderLineItem> linesToDelete = new List<WorkOrderLineItem>();
        linesToDeleteSet.remove('');
        linesToDeleteSet.remove(null);
        if(linesToDeleteSet.size() > 0){
            linesToDelete = SBR_3_0_WorkOrderDA.getLinesToDelete(linesToDeleteSet);
            if (linesToDelete.size() > 0){
                delete linesToDelete; 
            }
        }
        upsert linesToUpsert SF_PS_RM_External_Id__c;
    }
    
    private void processCreditLineItem(id woId, String eventOrigin, String currencyIsoCode){
        List<String> listMechNo = new List<String>();
        for(SF_PS_Credit_Line_Item__c cli : wo.CreditLineItem){
            listMechNo.add(cli.SF_PS_Mechanic_Name__c);
        }
        Set<String> mechNoSet = new Set<String>(listMechNo);
        List<ServiceResource> srList = [Select id ,Name , SF_PS_Mechanic_Id__c from  ServiceResource where SF_PS_Mechanic_Id__c IN :mechNoSet ];
        Map<String,String> mapMechNoToName = new Map<String,String>();
        for(ServiceResource sr :srList ){
            mapMechNoToName.put(sr.SF_PS_Mechanic_Id__c , sr.Name);
        }

        List<SF_PS_Credit_Line_Item__c> linestoUpsert =new List<SF_PS_Credit_Line_Item__c>();
        List<SF_PS_Credit_Line_Item__c> linesToDelete = new List<SF_PS_Credit_Line_Item__c>();
        linesToDeleteSet.remove('');
        linesToDeleteSet.remove(null);
        if(linesToDeleteSet.size() > 0){
            linesToDelete = SBR_3_0_WorkOrderDA.getCreditLinesToDelete(linesToDeleteSet); 
        }
        Map<String, Id> deleteLineIdMap = new Map<String, Id>();
        for(SF_PS_Credit_Line_Item__c oh : linesToDelete)
        {
            deleteLineIdMap.put(oh.SF_PS_RM_External_Id__c, oh.id);
        }
        for(SF_PS_Credit_Line_Item__c cli : wo.CreditLineItem){
            cli.WorkOrderId__c  = woId;
            cli.SF_PS_Labor_Code_Api__c = cli.SF_PS_Labor_Code__c;
            cli.SF_PS_Mechanic_ID_Api__c = cli.SF_PS_Mechanic_Name__c;
            cli.CurrencyIsoCode = currencyIsoCode;
            cli.SF_PS_Mechanic_Name_Api__c = mapMechNoToName.get(cli.SF_PS_Mechanic_Name__c); 
            if(deleteLineIdMap.get(cli.SF_PS_RM_External_Id__c) == null){
                linestoUpsert.add(cli); 
            } 
        }
        if (linesToDelete.size() > 0){
            delete linesToDelete; 
        }
        upsert linesToUpsert SF_PS_RM_External_Id__c;       
    }
    
    private void processCreditedParts(id woId, String eventOrigin, String currencyIsoCode){
        /*
        List<SF_PS_Credited_Part__c > pcToUpsert = new List<SF_PS_Credited_Part__c >();
        for (SF_PS_Credited_Part__c  qp : wo.CreditParts) {
            qp.SF_PS_Work_Order__c  = woId;
            if (String.isBlank(qp.SF_PS_ItemType__c)) {
                qp.SF_PS_ItemType__c = 'MI';
            } else {
                qp.SF_PS_ItemType__c = qp.SF_PS_ItemType__c;
            }
            pcToUpsert.add(qp);
        }
        upsert pcToUpsert SF_PS_RM_External_Id__c;
        */

        
        List<String> skuList = new List<String>();
        for (SF_PS_Credited_Part__c  qp : wo.CreditParts) {
            skuList.add(qp.SF_PS_Product2Id__c) ;
        }
        set<String> skuSet = new Set<String>(skuList);
        List<Product2> productList = [Select id , SM_PS_Item_number__c,  Product_SKU__c from Product2 where Product_SKU__c in : skuSet ];
        Map<string , Product2 > mapSkuToId = new Map<String,Product2>();
        for (Product2 products :productList){
            mapSkuToId.put(products.Product_SKU__c ,products );
        }

        List<SF_PS_Credited_Part__c > pcToUpsert = new List<SF_PS_Credited_Part__c >();
        for (SF_PS_Credited_Part__c  qp : wo.CreditParts) {
            qp.SF_PS_Work_Order__c  = woId;
            qp.SF_PS_Selling_Price_Api__c = qp.SF_PS_Selling_Price__c;
            qp.SF_PS_Cost_Price_Api__c = qp.SF_PS_Cost_Price__c;
            qp.SF_PS_Labor_Code_Api__c = qp.SF_PS_Labor_Code__c;
            qp.SF_PS_Line_Type_Api__c = qp.SF_PS_Line_Type__c;
            qp.CurrencyIsoCode = currencyIsoCode;
            
            if (String.isBlank(qp.SF_PS_ItemType__c)) {
                qp.SF_PS_ItemType__c = 'MI';
            } else {
                qp.SF_PS_ItemType__c = qp.SF_PS_ItemType__c;
            }
            if(inWorkOrder.SF_PS_BillCustOrLoc__c == 'C' || inWorkOrder.SF_PS_BillCustOrLoc__c == '$'|| qp.SF_PS_ItemType__c=='MI' ){
                qp.SF_PS_Credit_Price__c = qp.SF_PS_Selling_Price__c; 
            }else {
                qp.SF_PS_Credit_Price__c = qp.SF_PS_Cost_Price__c;
            }
            if(mapSkuToId.get(qp.SF_PS_Product2Id__c) != null){
                qp.SF_PS_Product__c =  mapSkuToId.get(qp.SF_PS_Product2Id__c).id;
                qp.SF_PS_Product2Id_Api__c = qp.SF_PS_Product2Id__c;
            }
            
            pcToUpsert.add(qp);
        }
        upsert pcToUpsert SF_PS_RM_External_Id__c;



    }
    
    private void processQuotedLineItems(id woId, String eventOrigin, String currencyIsoCode){
        List<Quote_Line_Item__c> linesToUpsert = new List<Quote_Line_Item__c>();
        for (Quote_Line_Item__c qli : wo.QuoteLineItem){
            qli.WorkOrderId__c  = woId;
            qli.CurrencyIsoCode = currencyIsoCode;
            if(qli.SF_PS_Mechanic_Name__c != null){
                qli.SF_PS_Mechanic_Name__c = relServieResourceLineItems(qli.SF_PS_Mechanic_Name__c).Id;
            }
            List<Quote_Line_Item__c> CheckForDeletedLines = [SELECT Id,isDeleted FROM Quote_Line_Item__c WHERE SF_PS_RM_External_Id__c =: qli.SF_PS_RM_External_Id__c AND isDeleted = TRUE ALL ROWS];
            if (CheckForDeletedLines.size() == 0){
                linesToUpsert.add(qli);
            }
        }
        List<Quote_Line_Item__c> linesToDelete = new List<Quote_Line_Item__c>();
        linesToDeleteSet.remove('');
        linesToDeleteSet.remove(null);
        if(linesToDeleteSet.size() > 0){
            linesToDelete = SBR_3_0_WorkOrderDA.getQuoteLinesToDelete(linesToDeleteSet);
            if (linesToDelete.size() > 0){
                delete linesToDelete; 
            }
        }
        
        upsert linesToUpsert SF_PS_RM_External_Id__c;
    }
    
    
    private void processProductConsumed(id woId, String eventOrigin, String currencyIsoCode, String woPricebookEntryId){
        List<ProductConsumed> pcToUpsert = new List<ProductConsumed>();
        List<ProductConsumed> pcToDelete = new List<ProductConsumed>();
        
        //Get all Product Consumed for Workorder 
        List<ProductConsumed> pcToWorkOrder = SBR_3_0_WorkOrderDA.getrelProdConsumedToWO(woId);
        Map<String,ProductConsumed> externalIdToPc = new Map<String,ProductConsumed>();
        for(ProductConsumed woPc: pcToWorkOrder){
            externalIdToPc.put(woPc.SF_PS_RM_External_Id__c ,woPc);
        }
        Set<String> pcSet=new Set<String>();
        for(ProductConsumed pc: wo.productConsumed){
            pcSet.add(pc.Product2Id);
            ProductConsumed todelete = externalIdToPc.get(pc.SF_PS_RM_External_Id__c);
            string sku = pc.Product2Id;
            if(todelete != null && sku != todelete.Product2.Product_SKU__c){
                pcToDelete.add(todelete);  
            }
        }
        Map<String,PricebookEntry> getPriceBookEntryFromProduct = priceBookEntryFromProduct(pcSet, currencyIsoCode, woPricebookEntryId);
        if(pcToDelete != null){
            delete pcToDelete;
        }
        
        for (ProductConsumed pc: wo.productConsumed){
            ProductConsumed pci = pc;
            pci.WorkOrderId = woId;
            pci.SF_PS_RM_External_Id__c = pc.SF_PS_RM_External_Id__c;
            //pci.ProductItemId = relProdItems(pc.Product2Id).Id;

            List<ProductItem> piList = relProdItems(pc.Product2Id);
            if (piList.size() == 0){
                List<Product2> prdList=SBR_3_0_WorkOrderDA.getrelProd(pc.Product2Id);
                if(prdList.size() >0){
                    if(prdList[0].Product_Type__c == 'MISC Charge Items'){
                        //Empty as expected since we didnt find productitem


                    }
                    else{
                        throw new WorkOrderException('Product/Product Item not found');
                    }
                }
            }
            else{
                pci.SF_PS_Product_Item__c = piList[0].Id;
            }
            //pci.SF_PS_Product_Item__c  = relProdItems(pc.Product2Id).Id;


            Decimal tempSellingPrice = pc.SF_PS_Selling_Price__c;
            Decimal tempDiscountPercentage;
            if (pc.SF_PS_Discount_Percentage__c == null){
                tempDiscountPercentage = 0;
            }
            else{
                tempDiscountPercentage = pci.SF_PS_Discount_Percentage__c; 
            }
            pci.SF_PS_Orig_Selling_Price__c = pc.SF_PS_Selling_Price__c;
            pci.SF_PS_Discount_Percentage__c = pc.SF_PS_Discount_Percentage__c;
            pci.SF_PS_Selling_Price__c = tempSellingPrice * (1 - tempDiscountPercentage);
            pci.SF_PS_WorkOrder_Event_Origin__c  = eventOrigin;
            pci.SF_PS_Quantity__c= pc.SF_PS_Quantity__c;
            pci.QuantityConsumed =1;
            pci.SF_PS_Shipped_Qty__c=pc.SF_PS_Shipped_Qty__c;
            pci.SF_PS_Backordered_Qty__c=pc.SF_PS_Backordered_Qty__c;           
            pci.SF_PS_Original_Backordered_Quantity__c=pc.SF_PS_Original_Backordered_Quantity__c;
            pci.SF_PS_ItemType__c=pc.SF_PS_ItemType__c ;
            if(pc.SF_PS_ItemType__c == null || pc.SF_PS_ItemType__c==''){
                pci.SF_PS_ItemType__c='MI';
            }         
            pci.PricebookEntryId=getPriceBookEntryFromProduct.get(pc.Product2Id).id;
            pci.SF_PS_Description__c = getPriceBookEntryFromProduct.get(pc.Product2Id).Product2.Description__c;
            //pci.Product2Id = relProd(pc.Product2Id).Id; Product2Id isnt writable
            //REMOVE THE COMMENT BELOW IN THE NEXT SPRINT SINCE THE API NAME WOULD CHANGE IN THE NEXT SPRINGT
            //pci.QuantityUnitOfMeasure = pc.SF_PS_Unit_Of_Measure__c;
            pcToUpsert.add(pci);
        }
        upsert pcToUpsert SF_PS_RM_External_Id__c;
        
    }
    
    private void processQuotedParts(id woId, String currencyIsoCode){
        List<SF_PS_Quoted_Part__c> pcToUpsert = new List<SF_PS_Quoted_Part__c>();
        
        for (SF_PS_Quoted_Part__c qp: wo.QuotedParts){ 
            qp.SF_PS_WorkOrderId__c  = woId;
            //qp.SF_PS_ProductItem__c  = relProdItems(qp.SF_PS_Product2Id__c).Id;
            qp.SF_PS_Product2Id__c   = relProd(qp.SF_PS_Product2Id__c).Id  ;
            qp.SF_PS_Quantity__c  = qp.SF_PS_Quantity__c;
            qp.SF_PS_ItemType__c=qp.SF_PS_ItemType__c ;
            qp.CurrencyIsoCode = currencyIsoCode;
            if(qp.SF_PS_ItemType__c == null || qp.SF_PS_ItemType__c==''){  
                qp.SF_PS_ItemType__c='MI';
            }       
            Decimal tempSellingPrice = qp.SF_PS_Selling_Price__c;
            Decimal tempDiscountPercentage;
            if (qp.SF_PS_Discount_Percentage__c == null){
                tempDiscountPercentage = 0;
            }
            else{
                tempDiscountPercentage = qp.SF_PS_Discount_Percentage__c; 
            }
            qp.SF_PS_Orig_Selling_Price__c = qp.SF_PS_Selling_Price__c;
            qp.SF_PS_Discount_Percentage__c = qp.SF_PS_Discount_Percentage__c;
            qp.SF_PS_Selling_Price__c = tempSellingPrice * (1 - tempDiscountPercentage);
            pcToUpsert.add(qp);
        }
        upsert pcToUpsert SF_PS_RM_External_Id__c;
        
    }
    
    private void processMaintenanceSteps(Id woId){
        String equipementNo = relAsset.Id;
        List<SF_PS_Maintenance_Steps__c> msToUpsert = new List<SF_PS_Maintenance_Steps__c>();
        List<DueForService__c> dueForServiceTotal = [Select Id,SM_PS_External_ID__c,SM_PS_Step_Number__c from DueForService__c where SM_PS_Equipment_Number__c =:equipementNo  AND SM_PS_Company_Code__c =: wo.data.SF_PS_Company_Code__c];
        Map <String, DueForService__c> dueStepsMap = new Map<String, DueForService__c>();
        if (dueForServiceTotal.size() > 0){
            for (DueForService__c dfs : dueForServiceTotal){
                if (!(String.isBlank(dfs.SM_PS_Step_Number__c))){
                    String step= dfs.SM_PS_Step_Number__c;
                    dueStepsMap.put(step, dfs);
                }
            }
        }
        for (SF_PS_Maintenance_Steps__c ms : wo.maintenanceSteps){
            if (dueStepsMap.containsKey(ms.SF_PS_RM_Mtce_Steps_StepNumber__c)){
                DueForService__c dsi = dueStepsMap.get(ms.SF_PS_RM_Mtce_Steps_StepNumber__c);
                SF_PS_Maintenance_Steps__c msi = ms;
                msi.SF_PS_Work_Order__c = woId;
                msi.SF_PS_RM_External_Id__c = ms.SF_PS_RM_External_Id__c;
                msi.SF_PS_RM_Mtce_Mechanic_Name__c = relServieResourceLineItems(ms.SF_PS_RM_Mtce_Mechanic_Name__c).Id;
                msi.SF_PS_RM_Mtce_Steps_Y_N__c = ms.SF_PS_RM_Mtce_Steps_Y_N__c;
                msi.SF_PS_RM_Mtce_Steps_StepNumber__c = ms.SF_PS_RM_Mtce_Steps_StepNumber__c;
                msi.SF_PS_RM_Mtce_Steps_Meter_Reading_In__c = ms.SF_PS_RM_Mtce_Steps_Meter_Reading_In__c;
                msi.SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c = ms.SF_PS_RM_Mtce_Steps_Meter_Reading_Out__c;
                msi.SF_PS_RM_Mtce_Steps_Description__c = ms.SF_PS_RM_Mtce_Steps_Description__c;
                msi.SF_PS_RM_Mtce_Steps_Pass_Fail__c = 'P';
                msi.SF_PS_External_ID__c = dsi.SM_PS_External_ID__c;
                
                dueStepsMap.remove(ms.SF_PS_RM_Mtce_Steps_StepNumber__c);
                
                msToUpsert.add(msi);
            }
        }
        for (String step : dueStepsMap.keySet()) {
            DueForService__c dues = dueStepsMap.get(step);
            SF_PS_Maintenance_Steps__c msi = new SF_PS_Maintenance_Steps__c();
            msi.SF_PS_Work_Order__c = woId;
            msi.SF_PS_RM_Mtce_Steps_StepNumber__c = dues.SM_PS_Step_Number__c;
            msi.SF_PS_External_ID__c = dues.SM_PS_External_ID__c;
            
            msToUpsert.add(msi);
        }
        upsert msToUpsert SF_PS_External_ID__c;
    }
    
    private static String companyCode {
        get {
            if(wo.data.SF_PS_Company_Code__c != null) {
                return wo.data.SF_PS_Company_Code__c;
            }
            throw new WorkOrderException('Company Code is required!');
            
        }
        set;
    }
    
    private static String workOrderNumber {
        get {
            if(wo.data.SF_PS_RM_WO_Number__c != null) {
                return companyCode + '-' + wo.data.SF_PS_RM_WO_Number__c;
            }
            throw new WorkOrderException('WorkOrder Number is required!');
        }
        set;
    }
    
    private static RecordType relrecordType{
        get{
            if(relrecordType == null && wo.data.RecordTypeId != null && String.isNotBlank(wo.data.SF_PS_Work_Order_Des__c)){
                String WORecType=wo.data.RecordTypeId;
                List<RecordType> recTypeList = new List<RecordType>();
                if (WORecType == 'WORK ORDER'){
                    if (wo.data.SF_PS_Work_Order_Des__c != 'WORK ORDER CREDIT' && wo.data.SF_PS_Work_Order_Des__c != 'TAX CREDIT'){
                        recTypeList = SBR_3_0_WorkOrderDA.getWorkOrderRecordType('SF_PS_Inspection_Record','WorkOrder');
                    } else if (wo.data.SF_PS_Work_Order_Des__c == 'WORK ORDER CREDIT' || wo.data.SF_PS_Work_Order_Des__c == 'TAX CREDIT'){
                        recTypeList = SBR_3_0_WorkOrderDA.getWorkOrderRecordType('SF_PS_Credit','WorkOrder');
                    }
                    if (recTypeList.size()>0 ){
                        recordtype = recTypeList[0].DeveloperName;
                        return recTypeList[0];
                    }
                    else{
                        throw new WorkOrderException('RecordTypeId not found');
                    }
                } else if(WORecType == 'WORK ORDER QUOTE'){
                    recTypeList = SBR_3_0_WorkOrderDA.getWorkOrderRecordType('SF_PS_Quote','WorkOrder');
                    if (recTypeList.size()>0){
                        recordtype = recTypeList[0].DeveloperName;
                        return recTypeList[0];
                    }else{
                        throw new WorkOrderException('RecordTypeId not found');
                    }
                } else{
                    throw new WorkOrderException('RecordTypeId not found');
                }
            }
            return relrecordType;
        }
        set;
    }
    private static Account relAcct {
        get{
            if (relAcct == null && wo!=null && String.isNotBlank(wo.data.AccountId)){
                List<Account> acct =  new List<Account>();
                acct = SBR_3_0_WorkOrderDA.getRelatedAccount(wo.data.SF_PS_Company_Code__c+'-'+wo.data.AccountId, wo.data.SF_PS_Company_Code__c);
                if (acct.size() > 0 ){
                    return acct[0];
                }
                else{
                    throw new WorkOrderException('Account not found');
                }
            }
            return relAcct;
        }
        set;
    }
    
    private static User ownerFind {
        get{
            if (ownerFind == null && wo!= null && String.isNotBlank(wo.data.OwnerId)){
                List<User> userIds = new List<User>();
                userIds = SBR_3_0_WorkOrderDA.getUser(wo.data.OwnerId);
                if (userIds.size() > 0){
                    return userIds[0];
                }
                else{
                    throw new WorkOrderException('Owner not found');
                }
            }
            return ownerFind;
            
        }
        set;
    }
    
    private static Asset relAsset{
        get{
            if (relAsset == null && wo!= null && String.isNotBlank(wo.data.AssetId) && String.isNotBlank(wo.data.SF_PS_Company_Code__c)){
                List<Asset> asset = new List<Asset>();
                String assetLookup = companyCode +'-'+ wo.data.AssetId;
                asset = SBR_3_0_WorkOrderDA.getrelAsset(assetLookup);
                if (asset.size() > 0){
                    return asset[0];
                }
                else{
                    throw new WorkOrderException('Asset not found');
                }
            }
            return relAsset;
        }
        set;
    }
    
    private static ServiceTerritory relST{
        get{
            if (relST == null && wo!= null && String.isNotBlank(wo.data.SF_PS_Current_Loc__c)){
                List<ServiceTerritory> stList = new List<ServiceTerritory>();
                String countryCode;
                if(wo.data.SF_PS_Company_Code__c == '01') {
                    countryCode = 'US';
                }
                else{
                    countryCode = 'CA';
                }
                stList = SBR_3_0_WorkOrderDA.getrelST(wo.data.SF_PS_Current_Loc__c, countryCode);
                if (stList.size() > 0){
                    return stList[0];
                }
                else{
                    throw new WorkOrderException('Service territory not found');
                }
            }
            return relST;
        }
    }
    
    private static ServiceTerritory relSTExpense{
        get{
            if (relSTExpense == null && wo!= null && String.isNotBlank(wo.data.SF_PS_Expense_To_Loc__c)){
                List<ServiceTerritory> stList = new List<ServiceTerritory>();
                String countryCode;
                if(wo.data.SF_PS_Company_Code__c == '01') {
                    countryCode = 'US';
                }
                else{
                    countryCode = 'CA';
                }
                stList = SBR_3_0_WorkOrderDA.getrelST(wo.data.SF_PS_Expense_To_Loc__c, countryCode);
                if (stList.size() > 0){
                    return stList[0];
                }
                else{
                    throw new WorkOrderException('Service territory to expense not found');
                }
            }
            return relSTExpense;
        }
    }
    
    private static User relUser{
        get{
            if(relUser == null && wo!= null && String.isNotBlank(wo.data.SF_PS_Sales_Rep__c)){
                List<User> relUserList = new List<User>();
                relUserList = SBR_3_0_WorkOrderDA.getrelUser(wo.data.SF_PS_Sales_Rep__c);
                if (relUserList.size() > 0){
                    return relUserList[0];
                }
                else{
                    throw new WorkOrderException('Sales Rep not found');
                }
            }
            return relUser;
        }
    }
    
    private static AssociatedLocation relJobSite{
        get{
            if(relJobSite == null && wo!= null && String.isNotBlank(wo.data.SF_PS_Job_Site__c)){
                List<AssociatedLocation> relJobSiteList = new List<AssociatedLocation>();
                relJobSiteList = SBR_3_0_WorkOrderDA.getrelJobSite(wo.data.SF_PS_Job_Site__c);
                if (relJobSiteList.size() > 0){
                    return relJobSiteList[0];   
                }
                else{
                    throw new WorkOrderException('JobSite/Associated Location not found');
                }
            }
            return relJobSite;
        }
    }
    
    private static ServiceResource relServiceResource{
        get{
            if(relServiceResource == null && wo!= null && String.isNotBlank(wo.data.SF_PS_Service_Resource__c)){
                List<ServiceResource> relServiceResourceList = new List<ServiceResource>();
                relServiceResourceList = SBR_3_0_WorkOrderDA.getrelServiceResource(wo.data.SF_PS_Service_Resource__c);
                if (relServiceResourceList.size() > 0){
                    return relServiceResourceList[0];
                }
                else{
                    throw new WorkOrderException('Service Resource not found');
                }
            }
            return relServiceResource;
        }
    }
    
    private static ServiceResource relServieResourceLineItems(String mech){
        List<ServiceResource> relServiceResourceList = new List<ServiceResource>();
        if(wo!= null){
            relServiceResourceList = SBR_3_0_WorkOrderDA.getrelServiceResourceLineItems(mech);
            if (relServiceResourceList.size() > 0){
                return relServiceResourceList[0];
            }
        }
        return relServiceResourceList[0];
    }
    
    private static List<ProductItem> relProdItems(String prodId){
        String loc =branchlocationServiceTerritory();
        List<ProductItem> returnedProdItemList = new List<ProductItem>();
        if(wo!=null){
            returnedProdItemList = SBR_3_0_WorkOrderDA.getrelProdItems(prodId, loc);
            return returnedProdItemList;
        }
        return returnedProdItemList;
    }
    
    private static Product2 relProd(String prodId){
        List<Product2> returnedProdList = new List<Product2>();
        if(wo!=null){
            returnedProdList = SBR_3_0_WorkOrderDA.getrelProd(prodId);
            if (returnedProdList.size()==0){
                throw new WorkOrderException('Product not found');
            }
            else{
                return returnedProdList[0];
            }
        }
        return returnedProdList[0];
    }
    
    private static String branchlocationServiceTerritory(){
        String loc = [SELECT Branch_Location_Number__c FROM ServiceTerritory WHERE Id =: inWorkOrder.ServiceTerritoryId][0].Branch_Location_Number__c;
        return loc;
    }
    
    public Map<String,PricebookEntry> priceBookEntryFromProduct(Set<String> product2skuSet, String currencyIsoCode, String priceBookEntryId){
        List<PricebookEntry> pbeList=[SELECT id,Name, Product2.Description__c ,Product2.Product_SKU__c, Pricebook2.Name,CurrencyIsoCode,Pricebook2.Id from PricebookEntry where (Product2.Product_SKU__c IN :product2skuSet AND Pricebook2.Name='Standard Price Book' AND CurrencyIsoCode=:currencyIsoCode)];
        Map<String,PricebookEntry> pbeMap=new Map<String,PricebookEntry>();
        for(PricebookEntry pbe:pbeList){
            pbeMap.put(pbe.Product2.Product_SKU__c, pbe);
        }
        List<String> productSkuWithNoPbe=new List<String>();
        for(String product2sku : product2skuSet){
            if(pbeMap.keySet().contains(product2sku)==false){
                productSkuWithNoPbe.add(product2sku); 
            }
        }
        if(!productSkuWithNoPbe.isEmpty()){
            List<Product2> productIdList=[select id, name, Product_SKU__c from Product2 where Product_SKU__c IN :productSkuWithNoPbe];
            if(!productIdList.isEmpty()){
                Map<String, String> productIDofProductSku=new Map<String, String>();
                for(Product2 prod:productIdList){
                    productIDofProductSku.put(prod.Product_SKU__c,prod.id);
                }
                List<PricebookEntry> pbeToInsert=new List<PricebookEntry>();
                for(String productskuwithoutpbe:productSkuWithNoPbe){
                    PricebookEntry pbe=new PricebookEntry(Product2Id=productIDofProductSku.get(productskuwithoutpbe),
                                                          UnitPrice=0,CurrencyIsoCode=currencyIsoCode, Pricebook2Id=priceBookEntryId, isActive=true);
                    pbeToInsert.add(pbe);
                }
                if(!pbeToInsert.isEmpty()){
                    insert pbeToInsert;
                }
                List<PricebookEntry> insertedPbe=[SELECT id, Product2.Description__c, Product2.Product_SKU__c from PricebookEntry where Product2ID IN :productIDofProductSku.values()];
                for(PricebookEntry pbe:insertedPbe){
                    pbeMap.put(pbe.Product2.Product_SKU__c,pbe);
                }
            }
        }
        return pbeMap;      
    }
    
    private void setDeleteLinesData(String req) {
        // linesToDeleteSet = new Set<String>();
        JSONParser parser = JSON.createParser(req);
        while (parser.nextToken() != null) {
            if (parser.getCurrentToken() == JSONToken.FIELD_NAME)  {
                parser.nextValue();
                if (parser.getCurrentName() == 'deletedLines') { // deletedLineData
                    while(parser.nextToken() != JSONToken.END_ARRAY) {
                        if(parser.getCurrentToken() == JSONToken.FIELD_NAME) {
                            parser.nextValue();
                            if(parser.getCurrentName() == 'SF_PS_RM_External_Id__c'){ // global_line__c
                                linesToDeleteSet.add(parser.getText());
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
    
    
    public class WorkOrderRequestWrapper {
        public WorkOrder data {get; set;}
        public List<WorkOrderLineItem> workOrderLineItem {get; set;} 
        public List<ProductConsumed> productConsumed {get; set;}
        public List<SF_PS_Maintenance_Steps__c> maintenanceSteps {get; set;}
        public List<Quote_Line_Item__c> QuoteLineItem {get; set;}
        public List<SF_PS_Quoted_Part__c > QuotedParts {get; set;}
        public List<SF_PS_Credit_Line_Item__c> CreditLineItem {get; set;}
        public List<SF_PS_Credited_Part__c> CreditParts {get; set;}
    }
    
    public class WorkOrderException extends Exception {}
}