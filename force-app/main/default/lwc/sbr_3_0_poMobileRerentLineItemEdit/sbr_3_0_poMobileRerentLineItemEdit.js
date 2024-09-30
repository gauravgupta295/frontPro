import { LightningElement, api, track, wire } from 'lwc';
import { refreshApex } from '@salesforce/apex';
import { updateRecord, getRecordNotifyChange } from 'lightning/uiRecordApi';
import { getPicklistValues } from 'lightning/uiObjectInfoApi';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import UNIT_TYPES from '@salesforce/schema/PO_Line_Item__c.Units__c';
import getPOData from '@salesforce/apex/SBR_3_0_GetRatesRerentLineItemController.getPOData';
import updateRerent from '@salesforce/apex/SBR_3_0_GetRatesRerentLineItemController.updateRerent';
import getPOLineItembyId from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getPOLineItembyId';
import getRerentItems from '@salesforce/apex/SBR_3_0_GetRatesRerentLineItemController.getRerentItems';
import POLWCCSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import { loadStyle } from 'lightning/platformResourceLoader';

const objectFields = {
    recordTypeId: { apiName: 'RecordTypeId' },
    quantity: { apiName: 'Quantity__c' },
    unit: {apiName :'Units__c'},
    unitCost: {apiName :'Unit_Cost__c'},
    equipmentNumber: {apiName :'Equipment_Num__c', length : 10},
    messages: {apiName :'Messages__c'},
    glAccount:{apiName:'GL_Account__c'}
}

export default class Sbr_3_0_poMobileRerentLineItemEdit extends LightningElement {
    @api recordId;
    headerLabel = '';
    poLineItemRecord = {};
    productItem = {};
    dataToRefresh;
    recordTypeId;

    currentUnitCost;
    hasRendered = false;
    Min;
    Daily;
    Monthly;
    Weekly;
    Profitmin;  
    ProfitMarginMin;
    ProfitDay;
    ProfitMarginDay;
    ProfitWeekly;
    ProfitMarginWeekly;
    ProfitMonthly;
    ProfitMarginMonthly;
    VendorMin;
    VendorDay;
    VendorMonth;
    VendorWeek;
    Meter1;
    Meter2;
    Make;
    Model;
    Snumber;
    Quantity;
    TempMin;
    TempDaily;
    TempWeekly;
    TempMonthly;
    isbulk=false;
    dataToRefresh1;
    dataToRefresh2;

    unitTypes = [];
    lastCost;
    showPctIncrease;
    pctIncreaseMsg;

    objectFields = objectFields;
    error;
    isCSSLoaded = false;

    renderedCallback() {
        this.headerLabel = this.poLineItemRecord.Item_Number__c;
        if (!this.isCSSLoaded) {
            loadStyle(this, POLWCCSS + '/POlwc.css').then(() => {
                console.log('loaded successfully');
                this.isCSSLoaded = true;
            }).catch(error => {
                console.log('error loading CSS');
            });
        }
    }

        @wire(getPicklistValues, { recordTypeId: '$recordTypeId', fieldApiName: UNIT_TYPES })
         unitTypeValues({ data,error  }) {
        if (data) {
            this.unitTypes = [{ label: '--None--', value: '', selected: true }, ...data.values];
            //this.unitTypes = [...data.values].sort((a, b) => (a.label > b.label) ? 1 : -1);
        } else if (error) {
            this.error = error;
            this.unitTypes = undefined;
        }
    }

    handleInputChange(event) {
        const field = event.currentTarget.dataset.field;
        // Pricing Info
        if (field === 'orderQuantity') {
            this.poLineItemRecord.Quantity__c = event.target.value;
        }
        else if (field === 'unit') {
            this.poLineItemRecord.Units__c = event.detail.value;
        }
        else if (field === 'unitCost') {
            this.poLineItemRecord.Unit_Cost__c = event.target.value;
            this.calculateDiff();
        }
        // Additional Info
        else if (field === 'equipmentNumber') {
            this.poLineItemRecord.Equipment_Num__c = event.target.value;
        }
         else if (field === 'Make') {
            this.Make = event.target.value;
        }
         else if (field === 'Model') {
            this.Model = event.target.value;
        }
         else if (field === 'serialnumber') {
            this.Snumber = event.target.value;
        }
        else if (field === 'Meter1') {
            if(event.target.value != '') {
                this.Meter1 = event.target.value;
            }
            else {
                this.Meter1 = null;
            }
        }
        else if (field === 'Meter2') {
            if(event.target.value != '') {
                this.Meter2 = event.target.value;
            }
            else {
                this.Meter2 = null;
            }
        }
        else if (field === 'equipmentNumber') {
            this.Meter2 = event.target.value;
        }
        // Messages
        else if (field == 'messages') {
            this.poLineItemRecord.Messages__c = event.target.value;
        }
        else if (field == 'vendorminimum') {
            this.VendorMin = event.target.value;
            this.calculateProfitMin();
           }
        else if (field == 'vendorday') {
            this.VendorDay = event.target.value;
            this.calculateProfitDay();
           }
        else if (field == 'vendorweek'){
            this.VendorWeek = event.target.value;
            this.calculateProfitWeek();
           }
        else if (field == 'vendormonth'){
            this.VendorMonth = event.target.value;
            this.poLineItemRecord.Monthly=event.target.value;
            this.calculateProfitMonth();
           }
    }

    calculateProfitMonth(){
          let vmonth= this.VendorMonth;
          if(this.TempMonthly==0 ||this.TempWeekly==null){
            this.ProfitMonthly=0;
            this.ProfitMonthly=this.formatCurrency(this.ProfitMonthly);
            this.ProfitMarginMonthly=0+ '%';
          }else{
          this.ProfitMonthly =this.formatCurrency(this.TempMonthly-vmonth);
          this.ProfitMarginMonthly = (((this.TempMonthly-vmonth)/vmonth)*100).toFixed(2)+ '%';
          }
    }

    calculateProfitWeek(){
        let vweek= this.VendorWeek;
        if(this.TempWeekly==0||this.TempWeekly==null){
              this.ProfitWeekly=0;
              this.ProfitWeekly=this.formatCurrency(this.ProfitWeekly);
            this.ProfitMarginWeekly=0+ '%';
          }else{
          this.ProfitWeekly = this.TempWeekly-vweek;
            this.ProfitWeekly=this.formatCurrency(this.ProfitWeekly);
          this.ProfitMarginWeekly = (((this.TempWeekly-vweek)/vweek)*100).toFixed(2)+ '%';
          }
    }
    
    calculateProfitDay(){
          let vday= this.VendorDay;
          if(this.TempDaily==0 ||this.TempDaily==null){
              this.ProfitDay=0;
              this.ProfitDay=this.formatCurrency(this.ProfitDay);
            this.ProfitMarginDay=0+ '%';
          }else{
          this.ProfitDay = this.TempDaily-vday;
          this.ProfitDay=this.formatCurrency(this.ProfitDay);
          this.ProfitMarginDay = (((this.TempDaily-vday)/vday)*100).toFixed(2)+ '%';
          }
    }
    
    calculateProfitMin(){
          let vmin= this.VendorMin;
          if(this.TempMin==0 ||this.TempMin==null||this.VendorMin==0||this.VendorMin==null){
              this.Profitmin=0;
              this.Profitmin=this.formatCurrency(this.Profitmin);
            this.ProfitMarginMin=0+'%';
          }else{
          console.log('Vmin', this.VendorMin)
          this.Profitmin = this.TempMin-vmin;
          this.Profitmin=this.formatCurrency(this.Profitmin);
          this.ProfitMarginMin = (((this.TempMin-vmin)/vmin)*100).toFixed(2)+ '%';
          }
    }

    handleCancel() {
        console.log('close');
        refreshApex(this.dataToRefresh);
        //console.log('close');
        this.dispatchEvent(new CustomEvent('close'));
    }

    async handleSave() {
         const allValid = [
            ...this.template.querySelectorAll('[data-validation="true"]')]
            .reduce((validSoFar, inputCmp) => {
                inputCmp.reportValidity();
                return validSoFar && inputCmp.checkValidity();
            }, true);
        if (allValid) {
            // to update the PO Line Item record
            const fields = {};
            fields['Id'] = this.recordId;
            fields[objectFields.recordTypeId.apiName] = this.poLineItemRecord.RecordTypeId;
            fields[objectFields.quantity.apiName] = this.poLineItemRecord.Quantity__c;
            fields[objectFields.unitCost.apiName] = this.poLineItemRecord.Monthly;
            fields[objectFields.equipmentNumber.apiName] = this.poLineItemRecord.Equipment_Num__c;
            fields[objectFields.messages.apiName] = this.poLineItemRecord.Messages__c;

            const recordInput = { fields };

            try {
                this.showSpinner = true;
                await updateRecord(recordInput)
                this.updateRerent();
                console.log('Record updated successfully');
                this.showSpinner = false;
                await getRecordNotifyChange([{ recordId: this.recordId }]);
                await refreshApex(this.dataToRefresh);
                await refreshApex(this.dataToRefresh2);
                this.handleCancel();
            }
            catch (error) {
                this.showSpinner = false;

                this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error updating records',
                        message: 'An error occurred while trying to update the record.',
                        variant: 'error'
                    })
                );
            }
            console.log('After updateRecord');
        }
    }

    @wire(getPOData,{RerentLineItemId : '$recordId'})
            getrate({ data,error}){
            console.log('Inside RentalMan');
            if(data){
              console.log('Data',data);
               let parsedData = JSON.parse(data);
               if(parsedData.data!=null){
                this.Min = this.formatCurrency(parsedData.data.items[0].rates.bookRates.minimum);
                this.Daily=this.formatCurrency(parsedData.data.items[0].rates.bookRates.daily);
                this.Monthly=this.formatCurrency(parsedData.data.items[0].rates.bookRates.monthly);
                this.Weekly=this.formatCurrency(parsedData.data.items[0].rates.bookRates.weekly);
                this.TempMin=parsedData.data.items[0].rates.bookRates.minimum;
                if(this.TempMin==0||this.VendorMin==0||this.VendorMin==null){
                this.Profitmin=0;
                this.Profitmin=this.formatCurrency(this.Profitmin);
                this.ProfitMarginMin=0+'%';
                }else{
                this.Profitmin = this.TempMin-this.VendorMin;
                this.Profitmin=this.formatCurrency(this.Profitmin);
                this.ProfitMarginMin = (((this.TempMin-this.VendorMin)/this.VendorMin)*100).toFixed(2)+ '%';
                }
                this.TempDaily=parsedData.data.items[0].rates.bookRates.daily;
                 if(this.TempDaily==0||this.VendorDay==0||this.VendorDay==null){
                    this.ProfitDay=0;
                    this.ProfitDay=this.formatCurrency(this.ProfitDay);
                    this.ProfitMarginDay=0+ '%';
                    }else{
                     this.ProfitDay = this.TempDaily-this.VendorDay;
                     this.ProfitDay=this.formatCurrency(this.ProfitDay);
                    this.ProfitMarginDay = (((this.TempDaily-this.VendorDay)/this.VendorDay)*100).toFixed(2)+ '%';
                    }
                    
                this.TempWeekly=parsedData.data.items[0].rates.bookRates.weekly;
                    if(this.TempWeekly==0||this.VendorWeek==0||this.VendorWeek==null){
                    this.ProfitWeekly=0;
                    this.ProfitWeekly=this.formatCurrency(this.ProfitWeekly);
                    this.ProfitMarginWeekly=0+ '%';
                    }else{
                    this.ProfitWeekly = this.TempWeekly-this.VendorWeek;
                    this.ProfitWeekly=this.formatCurrency(this.ProfitWeekly);
                    this.ProfitMarginWeekly = (((this.TempWeekly-this.VendorWeek)/this.VendorWeek)*100).toFixed(2)+ '%';
                    }
                    
                this.TempMonthly=parsedData.data.items[0].rates.bookRates.monthly;
                if(this.TempMonthly==0||this.VendorMonth==0||this.VendorMonth==null){
                this.ProfitMonthly=0;
                this.ProfitMonthly=this.formatCurrency(this.ProfitMonthly);
                this.ProfitMarginMonthly=0+ '%';
                    }else{
                    this.ProfitMonthly = this.TempMonthly-this.VendorMonth;
                    this.ProfitMonthly=this.formatCurrency(this.ProfitMonthly);
                    this.ProfitMarginMonthly = (((this.TempMonthly-this.VendorMonth)/this.VendorMonth)*100).toFixed(2)+ '%';
                    } 
                console.error(this.Min);
                console.error(this.Daily);
                console.error(this.Monthly);
                console.error(this.Weekly);
            }  else {
             this.dispatchEvent(
                    new ShowToastEvent({
                        title: 'Error',
                        message: 'No rates returned',
                        variant: 'Error'
                    })
                );
                this.Min=this.formatCurrency(0);;
                this.Profitmin=this.formatCurrency(0);
                this.ProfitMarginMin=0+'%';
                this.Daily=this.formatCurrency(0);;
                this.ProfitDay=this.formatCurrency(0);;
                this.ProfitMarginDay=0+'%';
                this.Weekly=this.formatCurrency(0);;
                this.ProfitWeekly=this.formatCurrency(0);;
                this.ProfitMarginWeekly=0+'%';
                this.Monthly=this.formatCurrency(0);;
                this.ProfitMonthly=this.formatCurrency(0);
                this.ProfitMarginMonthly=0+'%';
                   }         
            }
            else if (error){
                
            this.error = error;
            }
    }
    
    @wire(getRerentItems,{RerentLineItemId : '$recordId'})
    getRerentdata(result){
        this.dataToRefresh1 = result;
        console.log('Inside Get Rerent');
        if(result.data){
            let data = result.data;
            console.log('Data',data);
            this.Meter1=data[0].Current_Mi_Hr__c;
            this.Meter2=data[0].Current_Mi_Hr_2__c;
            this.Make=data[0].Make__c;
            this.Model=data[0].Model__c;
            
            console.log('Make', this.Make);
            this.VendorMin = data[0].Min_Rate__c;
            console.log('VendorMin', this.VendorMin);
            this.VendorDay = data[0].Day_Rate__c;
            this.VendorWeek = data[0].Week_Rate__c;
            this.VendorMonth = data[0].Month_Rate__c;
            this.Snumber=data[0].Serial_Number__c;
            if(this.VendorMin!=0 && this.VendorMin!=undefined && this.VendorMin!=null && this.TempMin!=null && this.TempMin!=undefined && this.TempMin!=0){
            this.Profitmin = this.TempMin-this.VendorMin;
                this.Profitmin=this.formatCurrency(this.Profitmin);
                this.ProfitMarginMin = (((this.TempMin-this.VendorMin)/this.VendorMin)*100).toFixed(2)+ '%';
            }else if (this.VendorMin==0||this.VendorMin==null||this.VendorMin==undefined||this.TempMin==undefined ||this.TempMin==null ||this.TempMin==0){
               this.Profitmin=0;
               this.Profitmin=this.formatCurrency(this.Profitmin);
               this.ProfitMarginMin=0.00+'%';
            
            }
            else{
                this.error=error;
            }
             if(this.VendorDay!=0 && this.VendorDay!=undefined && this.TempDaily!=null &&this.TempDaily!=0 && this.TempDaily!=undefined &&this.TempDaily!=null){
            this.ProfitDay = this.TempDaily-this.VendorDay;
                     this.ProfitDay=this.formatCurrency(this.ProfitDay);
                    this.ProfitMarginDay = (((this.TempDaily-this.VendorDay)/this.VendorDay)*100).toFixed(2)+ '%';
             }
             else if (this.VendorDay==0||this.VendorDay==null||this.VendorDay==undefined||this.TempDaily==undefined ||this.TempDaily==null ||this.TempDaily==0){
                   this.ProfitDay=0;
                   this.ProfitDay=this.formatCurrency(this.ProfitDay);
                   this.ProfitMarginDay=0.00+'%';
             }
             else{
                 this.error=error;
             }
                if(this.VendorWeek!=0 && this.VendorWeek!=undefined && this.VendorWeek!=null && this.TempWeekly!=null && this.TempWeekly!=undefined && this.TempWeekly!=0){
             this.ProfitWeekly = this.TempWeekly-this.VendorWeek;
                    this.ProfitWeekly=this.formatCurrency(this.ProfitWeekly);
                    this.ProfitMarginWeekly = (((this.TempWeekly-this.VendorWeek )/this.VendorWeek)*100).toFixed(2)+ '%';
                }
                else if (this.VendorWeek==0||this.VendorWeek==null||this.VendorWeek==undefined||this.TempWeekly==undefined ||this.TempWeekly==null ||this.TempWeekly==0){
                   this.ProfitWeekly=0;
                    this.ProfitWeekly=this.formatCurrency(this.ProfitWeekly);
                   this.ProfitMarginWeekly=0.00+'%';
                }

                else{
                    this.error=error;
                }
                if(this.VendorMonth!=0 && this.VendorMonth!=undefined && this.VendorMonth!=null && this.TempMonthly!=null && this.TempMonthly!=undefined && this.TempMonthly!=0){
            this.ProfitMonthly = this.TempMonthly-this.VendorMonth;
                    this.ProfitMonthly=this.formatCurrency(this.ProfitMonthly);
                    this.ProfitMarginMonthly = (((this.TempMonthly-this.VendorMonth)/this.VendorMonth)*100).toFixed(2)+ '%';
                }
                else if (this.VendorMonth==0||this.VendorMonth==null||this.VendorMonth==undefined||this.TempMonthly==undefined ||this.TempMonthly==null ||this.TempMonthly==0){
                   this.ProfitMonthly=0;
                   this.ProfitMonthly=this.formatCurrency(this.ProfitMonthly);
                   this.ProfitMarginMonthly=0.00+'%';
                }

                else{
                    this.error=error;
                }
        }  else if(result.error) {
            this.error = result.error;
        }           
    }

    @wire(getPOLineItembyId,{poLineItemId : '$recordId'})
    getdata(result){
        this.dataToRefresh2 = result;
        console.log('Inside Get PO Data');
        if(result.data){
            let data = result.data;
            this.poLineItemRecord = JSON.parse(JSON.stringify(data));
            console.log('Data',data);
            this.recordTypeId =data.RecordTypeId;
            this.isbulk=data.Bulk_Item__c;
            console.log('isbulk', data.Bulk_Item__c);
            console.log('isbulk', this.isbulk);
            if(this.isbulk==true){
                this.isbulk=false;
            }else{
                this.isbulk=true;
            }
            this.Quantity = data.Quantity__c;
    }  else if(result.error) {
            this.error = result.error;
        }                   
    }
    
    formatCurrency(value) {
        return new Intl.NumberFormat('en-US', { style: 'currency', currency: 'USD' }).format(value);
    }
    async updateRerent(){
        console.log('VendorMin',this.VendorMin);
        console.log('VendorMin',this.Snumber);
         updateRerent({recordId:this.recordId ,Min:this.VendorMin,Day:this.VendorDay,Week:this.VendorWeek,fourWeek:this.VendorMonth,Equipment:this.poLineItemRecord.Equipment_Num__c,Make:this.Make,Model:this.Model,Serial:this.Snumber,Meter1:this.Meter1, Meter2:this.Meter2 })
            .then(result => {
                this.data = result;
                refreshApex(this.dataToRefresh1);
                refreshApex(this.dataToRefresh2);
                this.close("OK");
            })
            .catch(error => {
                console.log(error);
            });
    }

}