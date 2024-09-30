import { wire, api } from 'lwc';
import LightningModal from 'lightning/modal';
import RECORD_TYPE_FIELD from '@salesforce/schema/PPA_Price_List__c.RecordType.DeveloperName';
import STATUS_FIELD from '@salesforce/schema/PPA_Price_List__c.PPA_Status__c';
import RA_IMPROVEMENT_FIELD from '@salesforce/schema/PPA_Price_List__c.PPA_RA_Improvement__c';
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
import applyMassEditUpdates from '@salesforce/apex/PPA_CatClassMassEditController.applyMassEditUpdates';
import { refreshApex } from '@salesforce/apex';

export default class PPA_CatClassMassEditLWC extends LightningModal {
    @api recordId;
    @api allRecords;
    @api selectedRows;
    recordTypeName;
    recordStatus;
    raImprovePct;
    dayValue;
    weekValue;
    monthValue;
    error;
    showSpinner = false;

    @wire(getRecord, { recordId: '$recordId', fields: [RECORD_TYPE_FIELD, STATUS_FIELD, RA_IMPROVEMENT_FIELD] })
    wiredRecord(result) {
        this.dataToRefresh = result;
        if (result.data) {
            this.recordTypeName = getFieldValue(result.data, RECORD_TYPE_FIELD);
            this.recordStatus = getFieldValue(result.data, STATUS_FIELD);
            this.raImprovePct = getFieldValue(result.data, RA_IMPROVEMENT_FIELD).toFixed(2);
            this.error = null;
        } else if (result.error) {
            this.error = result.error;
        }
    }
   
    handleCalculate() {
        let dayCalc;
        let weekCalc;
        let monthCalc;
        let dayCalcChg;
        let weekCalcChg;
        let monthCalcChg;
        let monthNewValue;
        let raNumerator = 0.00;
        let raDenominator = 0.00;
        
        console.log(this.selectedRows);

        if(this.selectedRows.length > 0) {
            for(var i=0;i<this.allRecords.length;i++) {
                dayCalc = 0;
                weekCalc = 0;
                monthCalc = 0;
                dayCalcChg = 0;
                weekCalcChg = 0;
                monthCalcChg = 0;
                monthNewValue = 0;
    
                if(this.selectedRows.includes(this.allRecords[i].Id)) {

                    if(!isNaN(!this.allRecords[i].PPA_Old_Month__c) && !isNaN(this.allRecords[i].PPA_Month_Rental__c)  && !isNaN(this.monthValue)) {
                        if(this.allRecords[i].PPA_Old_Month__c > 0){
                            monthNewValue = this.allRecords[i].PPA_Old_Month__c * (1 + Number(this.monthValue)/100);
                            //Rounding removed for Month only calculation - PPA Phase 2.
                            monthCalcChg =  this.allRecords[i].notMonthOnly
                                                   ? ((this.handleRounding(monthNewValue) - this.allRecords[i].PPA_Old_Month__c) / this.allRecords[i].PPA_Old_Month__c)
                                                   : ((monthNewValue - this.allRecords[i].PPA_Old_Month__c).toFixed(2) / this.allRecords[i].PPA_Old_Month__c); 
                            monthCalc = monthCalcChg * this.allRecords[i].PPA_Month_Rental__c;
                        }
                    }
                    else {
                        monthCalc = this.allRecords[i].PPA_RA_Improvement_Month_Calc__c;
                    }
                    
                    if(!isNaN(!this.allRecords[i].PPA_Old_Week__c) && !isNaN(this.allRecords[i].PPA_Week_Rental__c) && !isNaN(this.weekValue)) {
                        if(this.allRecords[i].PPA_Old_Week__c > 0){
                            if(!this.allRecords[i].notMonthOnly && !isNaN(monthNewValue) && monthNewValue > 0){
                                weekCalcChg = ((monthNewValue / this.allRecords[i].Number_Of_Weeks__c).toFixed(2) - this.allRecords[i].PPA_Old_Week__c) / this.allRecords[i].PPA_Old_Week__c; 
                                weekCalc = weekCalcChg * this.allRecords[i].PPA_Week_Rental__c;
                            }
                            else{
                                weekCalcChg = (this.handleRounding(this.allRecords[i].PPA_Old_Week__c * (1 + Number(this.weekValue)/100)) - this.allRecords[i].PPA_Old_Week__c) / this.allRecords[i].PPA_Old_Week__c; 
                                weekCalc = weekCalcChg * this.allRecords[i].PPA_Week_Rental__c;
                            }
                        }
                    }
                    else {
                        weekCalc = this.allRecords[i].PPA_RA_Improvement_Week_Calc__c;
                    }

                    if(!isNaN(!this.allRecords[i].PPA_Old_Day__c) && !isNaN(this.allRecords[i].PPA_Day_Rental__c) && !isNaN(this.dayValue)) {
                        if(this.allRecords[i].PPA_Old_Day__c > 0){
                            if(!this.allRecords[i].notMonthOnly && !isNaN(monthNewValue) && monthNewValue > 0){
                                dayCalcChg = ((monthNewValue / this.allRecords[i].Number_Of_Days__c).toFixed(2) - this.allRecords[i].PPA_Old_Day__c) / this.allRecords[i].PPA_Old_Day__c; 
                                dayCalc = dayCalcChg * this.allRecords[i].PPA_Day_Rental__c;
                            }
                            else {
                                dayCalcChg = (this.handleRounding(this.allRecords[i].PPA_Old_Day__c * (1 + Number(this.dayValue)/100)) - this.allRecords[i].PPA_Old_Day__c) / this.allRecords[i].PPA_Old_Day__c; 
                                dayCalc = dayCalcChg * this.allRecords[i].PPA_Day_Rental__c;    
                            }
                        }
                    }
                    else {
                        dayCalc = this.allRecords[i].PPA_RA_Improvement_Day_Calc__c;
                    }
                   
                    raNumerator = raNumerator + monthCalc + weekCalc + dayCalc;
                }
                else {
                    raNumerator = raNumerator + this.allRecords[i].PPA_RA_Improvement_Numerator_Calc__c;
                }
    
                raDenominator = raDenominator + this.allRecords[i].PPA_RA_Improvement_Denominator_Calc__c;
            }

            if (raDenominator > 0){
                this.raImprovePct = (raNumerator / raDenominator) * 100;
            }
            else {
                this.raImprovePct = 0;
            }
            
            this.raImprovePct = this.raImprovePct.toFixed(2);
        }
    }

    handleCancel() {
        this.close();
    }
    
    handleApply() {
        let newDayValue = 0.00;
        let newWeekValue = 0.00;
        let newMonthValue = 0.00;
        let pushRecords = [];
        let tmpRec;
        let changesApplied;

        console.log(this.selectedRows);

        if(this.selectedRows.length > 0) {
            for(var i=0;i<this.selectedRows.length;i++) {
                changesApplied = false;
                tmpRec = [];
                tmpRec = this.allRecords.filter((record) => record.Id == this.selectedRows[i]);
    
                if(tmpRec.length == 1) {
                    if(!isNaN(tmpRec[0].PPA_Old_Day__c) && !isNaN(this.dayValue)) {
                        newDayValue = this.handleRounding(tmpRec[0].PPA_Old_Day__c * (1 + Number(this.dayValue)/100));
                        changesApplied = true;
                    }else if(!isNaN(tmpRec[0].PPA_New_Day__c)) {
                        newDayValue = tmpRec[0].PPA_New_Day__c.toFixed(2);
                    }

                    if(!isNaN(tmpRec[0].PPA_Old_Week__c) && !isNaN(this.weekValue)) {
                        newWeekValue = this.handleRounding(tmpRec[0].PPA_Old_Week__c * (1 + Number(this.weekValue)/100));
                        changesApplied = true;
                    } else if(!isNaN(tmpRec[0].PPA_New_Week__c)) {
                        newWeekValue = tmpRec[0].PPA_New_Week__c.toFixed(2);
                    }

                    if(!isNaN(tmpRec[0].PPA_Old_Month__c) && !isNaN(this.monthValue)) {
                        newMonthValue = tmpRec[0].notMonthOnly 
                                                ? this.handleRounding(tmpRec[0].PPA_Old_Month__c * (1 + Number(this.monthValue)/100))
                                                : (tmpRec[0].PPA_Old_Month__c * (1 + Number(this.monthValue)/100)).toFixed(2);
                        changesApplied = true;
                    } else if(!isNaN(tmpRec[0].PPA_New_Month__c)) {
                        newMonthValue = tmpRec[0].PPA_New_Month__c.toFixed(2);
                    }

                    if(!tmpRec[0].notMonthOnly && !isNaN(newMonthValue)){
                        newDayValue = (newMonthValue / tmpRec[0].Number_Of_Days__c).toFixed(2);
                        newWeekValue = (newMonthValue / tmpRec[0].Number_Of_Weeks__c).toFixed(2);
                        if (parseFloat(((newMonthValue / tmpRec[0].Number_Of_Weeks__c)).toFixed(2)) * tmpRec[0].Number_Of_Weeks__c < newMonthValue) {
                            newWeekValue = ((newMonthValue / tmpRec[0].Number_Of_Weeks__c) + 0.01).toFixed(2); // To avoid week error, add a penny.
                        }
                        changesApplied = true;
                    }

                    if(changesApplied) {
                        pushRecords.push({recordId: this.selectedRows[i], newDayValue: newDayValue, newWeekValue: newWeekValue, newMonthValue: newMonthValue});
                    }
                }
            }
        
            if(pushRecords.length > 0) {
                this.showSpinner = true;

                applyMassEditUpdates({ newValuesStr: JSON.stringify(pushRecords) })
                .then((result) => {  
                    refreshApex(this.dataToRefresh);                    
                    this.close('OK');
                })
                .catch((error) => {
                    this.showSpinner = false;
                    this.error = error;
                    console.log(error);
                });    
            }
            else {
                this.close();
            }
        }
    }

    handleRounding(amount) {
        let returnAmt;

        if(amount <= 25) {
            returnAmt = amount.toFixed(2);
        }
        else if(amount > 25 && amount <= 100) {
            returnAmt = amount.toFixed();
        }
        else {
            returnAmt = ((amount / 5).toFixed() * 5).toFixed();
        }

        return returnAmt; 
    }

    handleDayValue(event) {
        this.dayValue = event.target.value;
        if(this.dayValue == '') {
            this.dayValue = undefined;
        }
    }

    handleWeekValue(event) {
        this.weekValue = event.target.value;        
        if(this.weekValue == '') {
            this.weekValue = undefined;
        }
    }

    handleMonthValue(event) {
        this.monthValue = event.target.value;        
        if(this.monthValue == '') {
            this.monthValue = undefined;
        }
    }
}