import { LightningElement,api,track,wire } from 'lwc';
import {FlowNavigationBackEvent,FlowNavigationNextEvent,FlowNavigationFinishEvent,FlowAttributeChangeEvent} from "lightning/flowSupport";
import lightningDeleteModalLWC from 'c/sbr_3_0_sfsMobileGenericConfirmationModal';
import callEstimateApi from '@salesforce/apex/SBR_3_0_Estimates_API_Service.parseWorkOrder';
//import callEstimateApidummy from '@salesforce/apex/SBR_3_0_Estimates_API_Service.dummyRespTobeRemoved';

export default class Sbr_3_0_sfsDesktopPartsAndLaborReviewCmp extends LightningElement {

   @api recordToBeDeleted;  
   @api defaultParts; 
   @api defaultInventoryParts;
   @api defaultLabor;
   @api defaultTravel;
   @api defaultMiscItems;
   @api defaultOutSideLabor;
   @api baseUrlFromFlow
   @api companyCode;
   @api branchLoc;
   @api expenseToLoc;
   @api finalParts;
   @api finalInventoryParts;
   @api finalLaborTravels
   @api finalMiscItems;
   @api finalOutSideLabor; // No longer used as Outside Labor references are removed as per SERV-19167
   @api review='Normal';
   @api type='Inspection'
   @api defaultLaborCode;
   @api workOrder;
   @api totalTaxOnSales; // 01
   @api totalinvoiceAmount;
   @api totalStatetaxAmount ;// 02
   @api totalCountyTaxAmount; // 02
   @api is_Show_Damage_Estimator=false;
   @api showEstimatorButton = false;
   @api worOrderDesc;
   @track partTotal=0;
   @track laborTotal=0;
   @track travelTotal=0;
   @track miscTotal=0;
   @track partWithoutInventoryTotal=0;
   // @track outSideLaborTotal=0; //No longer used as Outside Labor references are removed as per SERV-19167

   totalPartsAmt=0;

   errorMessage;
   errorCode;
   disableSavePopUp = false;
   finalLabors;
   finalTravels;
   billCustLocL;
   woQuote;
   confirm=false;
   confirmForTaxCalculate=false; 
   disableButtonTaxCalculate=false;
   loadSpinner=false;
   hidePartsMisc=false;

   // parts


   connectedCallback(){
      if(this.worOrderDesc=='CHECK IN RETURN'||this.worOrderDesc=='REMARKETING INSPECTION'||this.worOrderDesc=='NEW RENTAL EQUIP COMMISSIONING'){ 
         this.hidePartsMisc=true;
      }
      console.log('default inventory'+JSON.stringify(this.defaultInventoryParts));
      console.log('Checkpoints Parts::'+JSON.stringify(this.defaultParts));
      console.log('Checkpoints misc::'+JSON.stringify(this.defaultMiscItems));

      if(this.review=='Clone'){
         this.assignDataForClone();
      }
      else if(this.expenseToLoc != 'L'){
         this.loadSpinner = true;
         this.gettaxcalucationanddiscountMethod(true , false);
      }

      if(this.type == 'Quote'){
         this.woQuote = true;
      } 
      else{
         this.woQuote = false;
      }

      if(this.expenseToLoc == 'L'){
         this.billCustLocL = true;
      }
      else{
         this.billCustLocL = false;
      }
      console.log('this.billCustLocL::'+this.billCustLocL);
      console.log('this.expenseToLoc::'+this.expenseToLoc);
   }

   assignDataForClone(){
      console.log(this.defaultParts);
      console.log('Parts '+JSON.stringify(this.defaultParts));
      console.log('misc '+JSON.stringify(this.defaultMiscItems));
      console.log('defaultTravel '+JSON.stringify(this.defaultTravel) );
      // Below is initial mandatory mapping used to populate data into LWC.

      let tempParts;
      let tempMisc;
      let tempTravel;
      let tempLabor;
      // let tempOutSideLabor; //Commented as per SERV-19167
      let tempInventoryParts;
      if(this.defaultParts){
         tempParts= JSON.parse(JSON.stringify(this.defaultParts));
         tempParts.forEach(data=>{
            data.Description=data.SF_PS_Description__c;
            if(this.type=='Inspection'){ //setting unique Id
               data.uuid=data.Id;
               data.Id=null;
               data.SM_PS_Quantity_Available__c=data.SF_PS_Available_Quantity__c;
               data.Item_Number__c=data.SF_PS_Part_Num__c;
               data.Stock_class__c = data.SF_PS_Stock_Class__c;
            }
            else if(this.type=='Quote'){ //data mappings
               //just for data mapping as unique field passed from flow(Id of Quoted parts)
               data.uuid=data.SF_PS_RM_External_Id__c;
               data.SF_PS_RM_External_Id__c=null;
               if(data.ProductItemId && data.ProductItemId.startsWith('01t'))
               {
                  //getting product2 Id(as no Mapping for direct product2 available)
               data.Product2Id=data.ProductItemId;
               }
               data.Item_Number__c=data.SF_PS_Part_Num__c;
               data.SM_PS_Quantity_Available__c= data.SF_PS_Already_Credited_Qty__c;
               data.Stock_class__c = data.SF_PS_Parts_Line_Num__c;
               data.SF_PS_Parts_Line_Num__c = '';
            }
            this.checkExtended(data,"PARTS");
         })
      }

      if(this.defaultInventoryParts){
         tempInventoryParts= JSON.parse(JSON.stringify(this.defaultInventoryParts));
         tempInventoryParts.forEach(data=>{
            data.Description=data.SF_PS_Description__c;
            if(this.type=='Inspection'){ //setting unique Id
               data.uuid=data.Id;
               data.Id=null;
               data.SM_PS_Quantity_Available__c=data.SF_PS_Available_Quantity__c;
               data.Item_Number__c=data.SF_PS_Part_Num__c;
               data.Stock_class__c = data.SF_PS_Stock_Class__c;
            }
            else if(this.type=='Quote'){ //data mappings
               //just for data mapping as unique field passed from flow(Id of Quoted parts)
               data.uuid=data.SF_PS_RM_External_Id__c;
               data.SF_PS_RM_External_Id__c=null;
               if(data.ProductItemId && data.ProductItemId.startsWith('01t'))
               {
                  //getting product2 Id(as no Mapping for direct product2 available)
               data.Product2Id=data.ProductItemId;
               }
               data.Item_Number__c=data.SF_PS_Part_Num__c;
               data.SM_PS_Quantity_Available__c= data.SF_PS_Already_Credited_Qty__c;
               data.Stock_class__c = data.SF_PS_Parts_Line_Num__c;
               data.SF_PS_Parts_Line_Num__c = '';
            }
            this.checkExtended(data,"PARTS");
         })
      }

      if(this.defaultMiscItems){
         tempMisc= JSON.parse(JSON.stringify(this.defaultMiscItems));
         tempMisc.forEach(data=>{
            console.log(data)
            console.log('data '+JSON.stringify(data));
            if(this.type=='Inspection'){
               //productItemId field on misc mapped with product2
               data.ProductItemId=data.Product2Id;
               data.Description=data.SF_PS_Description__c;
               data.uuid=data.Id;
               data.Item_Number__c=data.SF_PS_Part_Num__c;
               data.Id=null;
               data.Stock_class__c = data.SF_PS_Stock_Class__c;
            }
            else if(this.type=='Quote'){
               //just for data mapping as unique field passed from flow(Id of Quoted parts)
               data.uuid=data.SF_PS_RM_External_Id__c;
               data.SF_PS_RM_External_Id__c=null;
               data.Item_Number__c=data.SF_PS_Part_Num__c;
               if(data.ProductItemId && data.ProductItemId.startsWith('01t'))
               {
               data.Product2Id=data.ProductItemId;
               }
               data.Stock_class__c = data.SF_PS_Parts_Line_Num__c;
               data.SF_PS_Parts_Line_Num__c = '';
            }
            this.checkExtended(data,"MISC");
         })
      }
      if(this.defaultLabor){
         tempLabor= JSON.parse(JSON.stringify(this.defaultLabor));
         tempLabor.forEach(data=>{
            console.log(data)
            console.log('data '+JSON.stringify(data));
            data.uuid=data.Id; // for Inspection record
            if(this.type=='Quote'){
               //just for data mapping as Mechanic Id field passed from flow
               data.SF_PS_Mechanic_Id__c=data.SF_PS_RM_External_Id__c;
               //just for data mapping as unique field passed from flow(Id of Quote Line Item)
               data.uuid=data.SF_PS_RM_Item_Number__c;
               data.SF_PS_RM_Item_Number__c=null;
            }
            // data.ProductItemId=data.Product2Id;
            data.Id=null;
            // data.Description=data.SF_PS_Description__c;
            this.checkExtendedLabor(data);
         })
      }

      // Commented as part of SERV-19167
      // if(this.defaultOutSideLabor){
      //    tempOutSideLabor= JSON.parse(JSON.stringify(this.defaultOutSideLabor));
      //    tempOutSideLabor.forEach(data=>{
      //       console.log(data)
      //       console.log('data '+JSON.stringify(data));
      //       data.uuid=data.Id; // for Inspection record
      //       if(this.type=='Quote'){
      //          //just for data mapping as Mechanic Id field passed from flow
      //          data.SF_PS_Mechanic_Id__c=data.SF_PS_RM_External_Id__c;
      //          //just for data mapping as unique field passed from flow(Id of Quote Line Item)
      //          data.uuid=data.SF_PS_RM_Item_Number__c;
      //          data.SF_PS_RM_Item_Number__c=null;
      //       }
      //       // data.ProductItemId=data.Product2Id;
      //       data.Id=null;
      //       // data.Description=data.SF_PS_Description__c;
      //       this.checkExtendedLabor(data);
      //    })
      // }

      if(this.defaultTravel){
         tempTravel= JSON.parse(JSON.stringify(this.defaultTravel));
         tempTravel.forEach(data=>{
            data.uuid=data.Id; //for Inspection record
            if(this.type=='Quote'){
               //just for data mapping as Mechanic Id field passed from flow
               data.SF_PS_Mechanic_Id__c=data.SF_PS_RM_External_Id__c;
               //just for data mapping as unique field passed from flow(Id of Quote Line Item)
               data.uuid=data.SF_PS_RM_Item_Number__c;
               data.SF_PS_RM_Item_Number__c=null;
            }
            console.log(data)
            console.log('data '+JSON.stringify(data));
            
            //data.ProductItemId=data.Product2Id;
            data.Id=null;
            //data.Description=data.SF_PS_Description__c;
            this.checkExtendedLabor(data);
         })
      }
      this.defaultMiscItems=tempMisc;
      this.defaultParts=tempParts;
      this.defaultInventoryParts=tempInventoryParts;
      this.defaultLabor= tempLabor;
      // this.defaultOutSideLabor = tempOutSideLabor ;
      this.defaultTravel=tempTravel;
      this.loadSpinner = false;
   }

   // Check Extended field
   checkExtendedLabor(selectedRecord){
      selectedRecord.extended=selectedRecord.Duration*selectedRecord.SF_PS_Hourly_Internal_Rate__c 
   }

   //To handle update button disable or enable
   handledisableTax(event){
      this.disableButtonTaxCalculate=event.detail;
   }

   // To calculate extended amount
   checkExtended(selectedRecord,type){
      if(this.expenseToLoc=='L' && type=='PARTS' ){
         selectedRecord.extended=selectedRecord.SF_PS_Cost_Price__c*selectedRecord.QuantityConsumed;
      }
      else {
         selectedRecord.extended=selectedRecord.SF_PS_Selling_Price__c*selectedRecord.QuantityConsumed;
      }
   }

   

   // Handle next click on review
   async hanldeNext(){
      // // Misc Items
      let executeTaxCalculate=false;
      let partRecords={}

      let validMiscItemsRecords={};
      if(!this.hidePartsMisc){
         let miscItemCmp = this.template.querySelector('c-sbr_3_0_sfs-desktop-misc-items-cmp');
         miscItemCmp.screen='Review';
         let validMiscItems=miscItemCmp.hanldeNext();
         validMiscItemsRecords =JSON.parse(validMiscItems);
         console.log('Misc Item in handlenext ::'+ validMiscItems);
         console.log('from Misc Items '+ JSON.stringify(validMiscItemsRecords));
         
         // Parts
         let partCmp=this.template.querySelector('c-sbr_3_0_sfs-desktop-parts-cmp');
         partCmp.screen='Review';
         let validParts;
         if(this.type=='Inspection'){
            validParts = partCmp.handlePartsNext();
         }
         else{
            validParts=partCmp.hanldeNext();
            console.log('partCmp.hanldeNext()::'+partCmp.hanldeNext());
         }
         console.log('from parts '+ JSON.stringify(validParts));
         partRecords=JSON.parse(validParts);
         let showPopup=false;
         let executeNext=false;

         let combinedParts=this.combinePartsAndMisc(partRecords.records,validMiscItemsRecords.records);
         if(combinedParts && combinedParts.length>0){
            combinedParts.forEach(part=>{
               if(part.warningError){
                  showPopup=true;
               }
            })
         }

         console.log('this is showpopup '+showPopup);
         if(showPopup){
            await this.showPopup(showPopup);
            executeTaxCalculate=this.confirm;
            console.log('this is execute next'+executeTaxCalculate);
         }
         else{
            executeTaxCalculate=true;
         }
      }else{
         executeTaxCalculate=true;
         partRecords.isReview=true;
        // QuoteOutSidereview=true

         validMiscItemsRecords.isReview=true;
         this.finalParts=[];
         this.finalMiscItems=[];
          //this.finalOutSideLabor=[];
      }
       


      if(executeTaxCalculate){
         let lbrCmp=this.template.querySelector('c-sbr_3_0_sfs-desktop-labor-cmp');
         lbrCmp.screen='Review';
         let validLabor=lbrCmp.hanldeNext();
         let laborRecords=JSON.parse(validLabor);
         console.log(laborRecords)
         console.log('from labor '+ validLabor);
         
         // Commented as part of SERV-19167
         // let QuoteOutSidereview = true;
         // let validOutSideLaborRecords;
         // if(this.type == 'Quote' /*&& !this.hidePartsMisc*/){
         //    //OutSide Labor
         //    let outsideLaborCmp = this.template.querySelector('c-sbr_3_0_sfs-desktop-outside-labor-cmp');
         //    outsideLaborCmp.screen='Review';
         //    let validOutSideLabor=outsideLaborCmp.hanldeNext();
         //    validOutSideLaborRecords =JSON.parse(validOutSideLabor);
         //    QuoteOutSidereview = validOutSideLaborRecords.isReview;
         //    this.finalOutSideLabor=validOutSideLaborRecords.records;
         // }
       

         if(laborRecords.isReview &&  partRecords.isReview && validMiscItemsRecords.isReview){ // QuoteOutSidereview  is removed from the if condition as Outside Labor is not used as per SERV-19167
            if(!this.hidePartsMisc)
            {
            this.finalParts=partRecords.records;
            this.finalMiscItems=validMiscItemsRecords.records;
            this.finalInventoryParts= partRecords.recordsWithoutInventory;

            // Commented as part of SERV-19167
            // if(this.type == 'Quote'){
            //    this.finalOutSideLabor=validOutSideLaborRecords.records;
            // }
            }

            this.finalLaborTravels=laborRecords.records;
            this.finalTravels=laborRecords.travels;
            this.finalLabors=laborRecords.labors;

            console.log('finalParts '+JSON.stringify(this.finalParts));
            console.log('finalMisc '+JSON.stringify(this.finalMiscItems));
            console.log('final Travel '+JSON.stringify(this.finalLaborTravels));
            for (let mitems in this.finalMiscItems){
              this.finalMiscItems[mitems].isErrorPriceBookEntry=false;
            }
            await this.showPopupOfTaxCalculate();

            if(this.is_Show_Damage_Estimator && this.confirmForTaxCalculate)
            {
               const varFlowAttributeChangeEvent = new FlowAttributeChangeEvent('is_Show_Damage_Estimator',true);
               this.dispatchEvent(varFlowAttributeChangeEvent);
            }
            if(this.confirmForTaxCalculate){
               const navigateNextEvent = new FlowNavigationNextEvent();
               this.dispatchEvent(navigateNextEvent);
            }
         }
      }
   }

   // Handle Cancel Click
   handleCancel(event){
      // Navigation to Account List view(recent)
      let objectName='WorkOrder';
      window.location.href=`${window.location.origin}/lightning/o/${objectName}/list`;
   }

   // Handle Part Total
   handlePartTotal(event){
      let temp=event.detail;
      console.log("Part total:"+temp);
      this.partTotal =temp;
      console.log("IT WORKS Parts!!"+this.partTotal);
   }

   // Handle Part Without InventoryTotal
   handlePartWithoutInventoryTotal(event){
      let temp=event.detail;
      console.log("Part without inventory total:"+temp);
      this.partWithoutInventoryTotal =temp;
      console.log("IT WORKS Parts Without Inventory!!"+this.partWithoutInventoryTotal);
   }

   // Handle Labor Total
   handleLaborTotal(event){
      let temp=event.detail;
      console.log('data from labor '+temp );
      this.laborTotal=temp;
      console.log("IT WORKS Labor!!");
   }

   // Handle Travel Total
   handleTravelTotal(event){
      let temp=event.detail;
      console.log('data from travel '+temp );
      this.travelTotal=temp;
      console.log("IT WORKS Travel!!");
   }

   //Handle Misc Total
   handleMiscTotal(event){
   let temp=event.detail;
      console.log('data from Misc '+temp );
      this.miscTotal=temp;
      console.log("IT WORKS Misc Item!!");
   }

   //Handle OutSide Labor Total
   // handleOutSideLabor(event){
   //    let temp=event.detail;
   //    this.outSideLaborTotal = temp;
   // }

   // Total Amt
   get totalAmt() {
      // let total= Number(this.partTotal)+Number(this.partWithoutInventoryTotal)+Number(this.travelTotal)+Number(this.laborTotal) +Number(this.miscTotal) + Number(this.outSideLaborTotal); // Commented as part of SERV-19167
      let total= Number(this.partTotal)+Number(this.partWithoutInventoryTotal)+Number(this.travelTotal)+Number(this.laborTotal) +Number(this.miscTotal);
      console.log('thiis is total sum '+total);
      return total.toFixed(2);
   }

   // get totalPartsAmt() {
   //    let totalParts= Number(this.partTotal)+Number(this.partWithoutInventoryTotal);
   //    console.log('thiis is total sum for parts'+totalParts);
   //    return totalParts.toFixed(2);
   // }

   //To show model when selling price is less than warning price
   async showPopup(ispopup){
      await lightningDeleteModalLWC.open({
         size: 'small',
         description: 'Accessible description of modal purpose',
         content: 'Discount applied is greater than the suggested sale amount for one or more parts. Click ‘yes’ to proceed.',
         headerText:'Confirmation',
         onyesclick:(e)=>{
            this.confirm=true;
            return;
         }
      });
   }

   //Handler of calculate discount button
   taxCalucateButtonShowHide(event){
      if(this.expenseToLoc != 'L'){
         console.log('test');
         this.disableButtonTaxCalculate=event.detail;
         console.log('test'+this.disableButtonTaxCalculate);
         if(this.disableButtonTaxCalculate == false ){
            this.loadSpinner = true;
            this.retrieveFinalVariables();
            this.gettaxcalucationanddiscountMethod(false , false); 
         }
      }
   }

   // TO retrieve all final variable on discount calculation api hit
   retrieveFinalVariables(){
      let partCmp=this.template.querySelector('c-sbr_3_0_sfs-desktop-parts-cmp');
      partCmp.screen='Review';
      let validParts;
      if(this.type=='Inspection'){
         validParts = partCmp.handlePartsNext();
      }
      else{
         validParts=partCmp.hanldeNext();
         console.log('partCmp.hanldeNext()::'+partCmp.hanldeNext());
      }
      console.log('from parts '+ JSON.stringify(validParts));
      this.finalParts=JSON.parse(validParts).records;
      
      let lbrCmp=this.template.querySelector('c-sbr_3_0_sfs-desktop-labor-cmp');
      lbrCmp.screen='Review';
      let validLabor=lbrCmp.hanldeNext();
      this.finalLaborTravels=JSON.parse(validLabor).records;
      this.finalTravels=JSON.parse(validLabor).travels;
      this.finalLabors=JSON.parse(validLabor).labors;


      let miscItemCmp = this.template.querySelector('c-sbr_3_0_sfs-desktop-misc-items-cmp');
      miscItemCmp.screen='Review';
      this.finalMiscItems=JSON.parse(miscItemCmp.hanldeNext()).records;
      
      
      if(this.type == 'Quote'){
         // let outsideLaborCmp = this.template.querySelector('c-sbr_3_0_sfs-desktop-outside-labor-cmp');
         // outsideLaborCmp.screen='Review';
         // let validOutSideLabor=outsideLaborCmp.hanldeNext();
         // let validOutSideLaborRecords =JSON.parse(validOutSideLabor);
         // this.finalOutSideLabor=JSON.parse(validOutSideLabor).records;
         this.finalInventoryParts= JSON.parse(validParts).recordsWithoutInventory;
      }
   }


   //To Show calculated tax in modal form when hit update button on screen
   async showPopupOfTaxCalculate(){
      //api callout for tax calculation 
      this.totalPartsAmt=(Number(this.getPartsTotal(this.finalParts))+Number(this.getPartsTotal(this.finalInventoryParts))).toFixed(2);
      await this.gettaxcalucationanddiscountMethod(false, true);
      await lightningDeleteModalLWC.open({
         size: 'small',
         description: 'Tax Calucate By Modal',
         contentHide : true,
         content: '',
         headerText:'Tax Calculation',
         totalPartsAmt:this.totalPartsAmt,
         laborTotal:this.laborTotal,
         travelTotal:this.travelTotal,
         miscTotal:this.miscTotal,
         // outSideLaborTotal : this.outSideLaborTotal, // Commented as per SERV-19167
         workOrderTypeIsQuote : this.woQuote,
         totalAmt : this.totalAmt,
         totalTaxOnSales : this.totalTaxOnSales ,
         totalinvoiceAmount : this.totalinvoiceAmount,
         totalStatetaxAmount  : this.totalStatetaxAmount,
         totalCountyTaxAmount : this.totalCountyTaxAmount,
         companyCode : this.companyCode,
         disableSave : this.disableSavePopUp,
         showEstimatorButton : this.showEstimatorButton,
         errorMessage: `${this.errorCode} - ${this.errorMessage}`,
         onyesclick:(e)=>{
            console.log('tax calucate Yes');
            this.confirmForTaxCalculate=true;
            console.log('tax calucate Yes'+this.confirmForTaxCalculate);
            return;
         },
         onyesdeclick:(e)=>{
            this.confirmForTaxCalculate=true;
            // eslint-disable-next-line @lwc/lwc/no-api-reassignments
            this.is_Show_Damage_Estimator =true;
         }
      });
   }

   //api callout for tax calculation and discount
   async gettaxcalucationanddiscountMethod(isConnected, taxCalucate){
      console.log('test discount');
      let payload;
      let combinedParts;
      if(isConnected == true){
         combinedParts=this.combinePartsAndMisc(this.defaultParts,this.defaultMiscItems);
         // payload=this.createPayload(combinedParts,this.defaultLabor,this.defaultTravel,this.defaultOutSideLabor,taxCalucate); // this.defaultOutSideLabor is no longer used as per SERV-19167
         payload=this.createPayload(combinedParts,this.defaultLabor,this.defaultTravel,taxCalucate);
      }
      else{
         let calculatePartsRec;
         if(taxCalucate==false){
            combinedParts=this.combinePartsAndMisc(this.finalParts,this.finalMiscItems);
            calculatePartsRec = this.calculateDiscountFalseValues(combinedParts);
         }
         else{
            this.loadSpinner=true;
            let totalParts=[...this.finalParts,...this.finalMiscItems];
            if(this.finalInventoryParts){
               totalParts=[...totalParts,...this.finalInventoryParts];
            }
            console.log('this is total parts' + JSON.stringify(totalParts));
            calculatePartsRec = totalParts;
         }
         // payload=this.createPayload(calculatePartsRec,this.finalLabors,this.finalTravels,this.finalOutSideLabor,taxCalucate);// this.finalOutSideLabor is no longer used as per SERV-19167 
         payload=this.createPayload(calculatePartsRec,this.finalLabors,this.finalTravels,taxCalucate);
      }
      console.log('payload:::'+ JSON.stringify(payload));
      if(payload.parts.length || taxCalucate ){
         let finalPayload = JSON.stringify(payload);
         await callEstimateApi({woId:this.workOrder,existingPayload:finalPayload}).then(response=>{
         //await callEstimateApidummy({woId:this.workOrder,existingPayload:finalPayload}).then(response=>{
            console.log('response:::'+response);
            let result= JSON.parse(response);
            //Commenting it as when API fail we were not able to proceed further.
            if(this.isCalloutfailed(result)){
               console.log('callout failed '+result.error.message )
               if(!isConnected){
                  this.reset();
               } 
               this.loadSpinner = false;
               return;
            }
            console.log('api response '+JSON.stringify(result));
            this.getPayload(response,isConnected);

         }).catch(error=>{
            if(!isConnected){
               this.reset();
            } 
            console.log('estimate api error '+JSON.stringify(error));
            this.isCalloutfailedFromCatch(error.body.message,error.status);
            //this.disableSavePopUp = true;
            this.loadSpinner = false;
         })
      }
      else {
         if(!isConnected){
            this.reset();
         } 
         this.loadSpinner = false; 
      }
   }


   //To reset default variables with final variables
   reset(){
      //This block is for parts
      if(this.finalParts && this.finalParts.length){
         this.defaultParts=this.finalParts;
         this.setcalculateDiscount(this.defaultParts);
      }
      else{
         this.defaultParts=undefined;
      }

      //This block is for misc items
      if(this.finalMiscItems && this.finalMiscItems.length){
         this.defaultMiscItems=this.finalMiscItems;
         this.setcalculateDiscount(this.finalMiscItems);
      }
      else{
         this.defaultMiscItems=undefined;
      }

      //this block is for labors
      if(this.finalLabors && this.finalLabors.length){
         this.defaultLabor=this.finalLabors;
      }
      else{
         this.defaultLabor=undefined;
      }

      //this block is for travel
      if(this.finalTravels && this.finalTravels.length){
         this.defaultTravel=this.finalTravels;
      }
      else{
         this.defaultTravel=undefined;
      }

      // Commented as per SERV-19167
      //this block is for outside labor
      // if(this.finalOutSideLabor && this.finalOutSideLabor.length){
      //    this.defaultOutSideLabor=this.finalOutSideLabor;
      // }
      // else{
      //    this.defaultOutSideLabor=undefined;
      // }

      //this block is for non-inventory parts
      if(this.finalInventoryParts && this.finalInventoryParts.length){
         this.defaultInventoryParts=this.finalInventoryParts;
      }
      else{
         this.defaultInventoryParts=undefined;
      }
   }

   //Setting calculateDiscount flag back to true in case call out fails
   setcalculateDiscount(lines)
   {
      lines?.forEach(line=>{
         line.calculateDiscount=true;
      })
   }

   //To Merge records recieved from parts and misc cmp
   combinePartsAndMisc(Parts,Misc){
      let combinedRecords=[];
      if(Parts && Parts.length>0){
         combinedRecords=[...Parts];
         if(Misc && Misc.length>0){
            combinedRecords=[...Parts,...Misc];
         }
      }
      else if(Misc && Misc.length>0){
         combinedRecords=[...Misc];
      }
      return combinedRecords;
   }

   //To filter only those items where calculateDiscount=true
   calculateDiscountFalseValues(partsRecords){
      let dubParts = [];
      partsRecords.forEach((part) => {
         if(part.calculateDiscount == false){
            dubParts.push(part);
         }
      });
      return dubParts;
   }

   //To create payload to send to mule
   // createPayload(parts,insideLabor,mileage,outsideLabor,iscalculateTax){ // commented because outsideLabor is no longer used as per SERV-19167
      createPayload(parts,insideLabor,mileage,iscalculateTax){
      console.log('parts:'+ JSON.stringify(parts));
      let json={};
      if(parts && parts.length){
         json.parts = parts.reduce((acc, part) => {
            let result = {
            "cost": part.SF_PS_Cost_Price__c,
            //hardcoding
           "itemNumber": part.Item_Number__c,
           //"itemNumber": "HS1490",
            "laborCode": Number(part.SF_PS_Labor_Code__c),
            "quantity":part.QuantityConsumed,
            "sellingPrice":part.SF_PS_Selling_Price__c,
            "sourceReferenceLineNumber": part.uuid,
            "stockClass": part.Stock_class__c,
            //hardcoding
            // "stockClass": SBPOW,
            "unitOfMeasure": part.SF_PS_Unit_Of_Measure__c
            }
            if(iscalculateTax)
            {
               result.discountPercent=part.SF_PS_Discount_Percentage__c?part.SF_PS_Discount_Percentage__c:0;
            }
            result.sellingPrice=result.discountPercent>0?part.SF_PS_Orig_Selling_Price__c:part.SF_PS_Selling_Price__c;

            if(this.expenseToLoc=='L' && part.SF_PS_Parts_Type__c && part.SF_PS_Parts_Type__c=='Without Inventory' )
            {
               result.sellingPrice=part.SF_PS_Cost_Price__c;
            }

            return [...acc,result]
         }, [])
      }
      else{
         json.parts=[];
      }
      if(insideLabor && insideLabor.length){
         json.insideLabor = insideLabor.reduce((acc, labor) => {
            let result = { 
               "insideLaborHours": labor.Duration,
               "insideLaborRate":labor.SF_PS_Hourly_Internal_Rate__c,
               "laborCode": Number(labor.SF_PS_Labor_Code__c),
               "mechanicId": labor.SF_PS_Mechanic_Id__c
               // "sourceReferenceLineNumber": labor.uuid
            }
            return [...acc,result]
         }, [])
      }
      else{
         json.insideLabor=[];
      }

      // Removed as per SERV-19167
      // if(outsideLabor && outsideLabor.length){
      //    json.outsideLabor = outsideLabor.reduce((acc, labor) => {
      //       let result = {
      //          "laborCode": Number(this.defaultLaborCode),
      //          "outsideLaborCost":labor.SF_PS_PO_Cost__c,
      //          "outsideLaborPrice": labor.SF_PS_PO_Amount__c,
      //          "outsideLaborPoNumber": labor.SF_PS_Vendor_PO_Num__c
      //          // "sourceReferenceLineNumber": labor.uuid
      //       }
      //       return [...acc,result]
      //    }, [])
      // }
      // else{
      //    json.outsideLabor=[];
      // }

      json.outsideLabor=[]; // This attribute will an empty array. This is not removed because this attribute is being sent in the payload.

      if(mileage && mileage.length ){
         let tempmileage = mileage.reduce((acc, mile) => {
            let result = { 
               "mileageMiles": mile.Duration,
               "mileageRate":mile.SF_PS_Hourly_Internal_Rate__c,
               "laborCode": Number(mile.SF_PS_Labor_Code__c),
               "mechanicId": mile.SF_PS_Mechanic_Id__c
               // "sourceReferenceLineNumber": mile.uuid
            }
            return [...acc,result]
         }, [])

         json.mileage=tempmileage[0]

      }
      else{
         json.mileage={}
      }
      return json;
   }
   /*{"sourceWorkOrderNumber":"12345","workOrderNumber":999999999999,"parts":[{"lineItemType":"WO","sourceReferenceLineNumber":"string","itemNumber":"ALT001","stockClass":"ELEAL","quantity":1,"unitOfMeasure":"EA","sellingPrice":500,"listPrice":0,"discountPercent":10.25,"productSkuNumber":0},{"lineItemType":"WO","sourceReferenceLineNumber":"string","itemNumber":"AA-BATTERY","stockClass":"BATTE","quantity":1,"unitOfMeasure":"EA","sellingPrice":2.252,"listPrice":0,"discountPercent":0,"productSkuNumber":0}],"insideLabor":[{"lineItemType":"LI","sourceReferenceLineNumber":"string","mechanicId":"string","insideLaborHours":1,"insideLaborRate":500}],"outsideLabor":[{"lineItemType":"LO","sourceReferenceLineNumber":"string","poAmount":500}],"mileage":{"lineItemType":"MC","sourceReferenceLineNumber":"string","mileageMiles":1,"mileageRate":500},"taxInformation":[{"taxOnSales":151.04,"totalInvoiceAmount":1852.79,"stateTaxAmount":68.07,"countyTaxAmount":0}]}
    */

   //To map received response in required format
   getPayload(result,isconnected){
      let dubParts,dubMisc;
      var resultjson= JSON.parse(result);
      // CR SERV-18207 structure changed
      //let tempresult='{"sourceWorkOrderNumber":"12345","workOrderNumber":999999999999,"parts":[{"lineItemType":"WO","sourceReferenceLineNumber":"string","itemNumber":"ALT001","stockClass":"ELEAL","quantity":1,"unitOfMeasure":"EA","sellingPrice":500,"listPrice":0,"discountPercent":10.25,"productSkuNumber":0},{"lineItemType":"WO","sourceReferenceLineNumber":"string","itemNumber":"AA-BATTERY","stockClass":"BATTE","quantity":1,"unitOfMeasure":"EA","sellingPrice":2.252,"listPrice":0,"discountPercent":0,"productSkuNumber":0}],"insideLabor":[{"lineItemType":"LI","sourceReferenceLineNumber":"string","mechanicId":"string","insideLaborHours":1,"insideLaborRate":500}],"outsideLabor":[{"lineItemType":"LO","sourceReferenceLineNumber":"string","poAmount":500}],"mileage":{"lineItemType":"MC","sourceReferenceLineNumber":"string","mileageMiles":1,"mileageRate":500},"taxInformation":[{"taxOnSales":151.04,"totalInvoiceAmount":1852.79,"stateTaxAmount":68.07,"countyTaxAmount":0}]}';
      //resultjson= JSON.parse(tempresult);
      console.log('resultjson ',JSON.stringify(resultjson));
      console.log(resultjson);

      let disMap=this.createResponseMapping(resultjson)
      let taxInfoResult = resultjson['taxInformation'];
      this.totalTaxOnSales = taxInfoResult[0]?.taxOnSales; // 01
      this.totalinvoiceAmount=taxInfoResult[0]?.totalInvoiceAmount;
      this.totalStatetaxAmount = taxInfoResult[0]?.stateTaxAmount; // 02
      this.totalCountyTaxAmount = taxInfoResult[0]?.countyTaxAmount; // 02

      console.log('data map',JSON.stringify(disMap));

      if(isconnected== true){
         if(this.defaultParts && result){
            dubParts= JSON.parse(JSON.stringify(this.defaultParts));
            //var partsResult = resultjson['estimatesItems'];
            dubParts.forEach((oldParts) => {
               oldParts.SF_PS_Discount_Percentage__c=disMap[oldParts.uuid]?disMap[oldParts.uuid]:oldParts.SF_PS_Discount_Percentage__c
               oldParts.calculateDiscount = true;
            })
            if(this.defaultMiscItems && this.defaultMiscItems.length){
               dubMisc=JSON.parse(JSON.stringify(this.defaultMiscItems));
               dubMisc.forEach((oldmisc) => {
                  oldmisc.SF_PS_Discount_Percentage__c=disMap[oldmisc.uuid]?disMap[oldmisc.uuid]:oldmisc.SF_PS_Discount_Percentage__c
                  oldmisc.calculateDiscount = true;
               })
               this.defaultMiscItems = dubMisc;
            }
            this.defaultParts = dubParts;
            console.log('this.defaultParts:::'+JSON.stringify(this.defaultParts));
         }
         this.loadSpinner = false;
      } 
      else {
         if(this.finalParts && result){
            dubParts= JSON.parse(JSON.stringify(this.finalParts));
            dubParts.forEach((oldParts) => {
               oldParts.SF_PS_Discount_Percentage__c=( disMap[oldParts.uuid]!=undefined) ?disMap[oldParts.uuid]:oldParts.SF_PS_Discount_Percentage__c
               oldParts.SF_PS_Selling_Price__c=(oldParts.SF_PS_Orig_Selling_Price__c>=0 && oldParts.SF_PS_Discount_Percentage__c>0) ?  (Number((oldParts.SF_PS_Orig_Selling_Price__c - (oldParts.SF_PS_Orig_Selling_Price__c*oldParts.SF_PS_Discount_Percentage__c/100))).toFixed(2)) : oldParts.SF_PS_Selling_Price__c;
               this.checkExtended(oldParts,'PARTS');
               oldParts.calculateDiscount = true;
            })
            if(this.finalMiscItems && this.finalMiscItems.length){
               dubMisc=JSON.parse(JSON.stringify(this.finalMiscItems));

               dubMisc.forEach((oldmisc) => {
                  oldmisc.SF_PS_Discount_Percentage__c=( disMap[oldmisc.uuid]!=undefined) ?disMap[oldmisc.uuid]:oldmisc.SF_PS_Discount_Percentage__c
                  oldmisc.SF_PS_Selling_Price__c=(this.billCustLocL == false && oldmisc.SF_PS_Orig_Selling_Price__c>=0 && oldmisc.SF_PS_Discount_Percentage__c>0) ?  (Number((oldmisc.SF_PS_Orig_Selling_Price__c - (oldmisc.SF_PS_Orig_Selling_Price__c*oldmisc.SF_PS_Discount_Percentage__c/100))).toFixed(2)) : oldmisc.SF_PS_Selling_Price__c;
                  this.checkExtended(oldmisc,'MISC');
                  oldmisc.calculateDiscount = true;
               })
               this.finalMiscItems=dubMisc
            }
            this.finalParts= dubParts;
            //this.defaultParts = dubParts;
            
            this.reset();
            console.log('this.finalParts:::'+JSON.stringify(this.finalParts));
            
         }
         else{
            this.defaultParts=this.finalParts;

         }
         this.loadSpinner = false;
      }
   }
   // creates mapping of sourceReferenceLineNumber with discount
   createResponseMapping(response)
   {
     ///console.log('in mapping');
      console.log(response);
      let uidvsDiscount={};
      // response?.estimatesItems?.forEach(data=>{
      //    uidvsDiscount[data.sourceReferenceLineNumber]=data.discountPercent;
      // });
      response?.parts?.forEach(data=>{
         uidvsDiscount[data.sourceReferenceLineNumber]=data.discountPercent;
      });
      return uidvsDiscount



   }
   // checks for error in the response;
   isCalloutfailed(result)
   {
      if(result && result.error && result.error?.errorCode)
      {
         this.errorMessage=result.error.message;
         this.errorCode=result.error.errorCode;
         this.disableSavePopUp=true;
         return true;

      }
      this.disableSavePopUp=false;
      return false;

   }
   getPartsTotal(parts){
      let total=0;
      if(parts && parts.length)
      {
         total = parts.reduce((prev, next) => {
            if(next.extended){
               return Number(next.extended) + Number(prev);
            }
            else{
               return Number(prev);
            }
         }, 0)
      }
      console.log('total of parts is '+Number(total).toFixed(2));
      return Number(total).toFixed(2);
   }
   isCalloutfailedFromCatch(errorMessageDisplay,errorCodeDisplay){
      console.log('catch error is'+errorMessageDisplay);
      if(errorMessageDisplay)
      {
         this.errorMessage='Internal Server Error occurred. '+errorMessageDisplay;
         this.errorCode=errorCodeDisplay;
         this.disableSavePopUp=true;
      }

   }
}