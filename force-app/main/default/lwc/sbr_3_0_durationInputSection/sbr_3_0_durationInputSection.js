import { LightningElement, api, track} from 'lwc';
import FORM_FACTOR from '@salesforce/client/formFactor';
import getDateTimeOfUser from '@salesforce/apex/SBR_3_0_Generic.getDateTimeOfUser';

//Current Format of (Order/quote) duration
const DURATION_VALUE = {
   DAY: 'Day',
   WEEK: 'Week',
   MONTH: '4 Week',
   CUSTOM: 'Custom',
};

export default class Sbr_3_0_durationInputSection extends LightningElement {

    @api estDuration;
    @api duration;
    @api startDate;
    @api endDate;
    today;
    minEndDate;
    formattedCurrentDateTime;
    isInvalidStartDate = false ;
    isInvalidEndDate = false ;
    @track isMobile = false;

    constructor(){
        super();
        if(this.startDate) return;
        getDateTimeOfUser() 
        .then(result => {
            this.startDate = result;
        })
        .catch(error => {
            console.error(' Error Information =>', error);
            this.error = error;
        })
    }
    

    connectedCallback() {
        this.updateInputDurationValue(); // update Duration to match with the (Order/quote) duration format
        if(FORM_FACTOR === 'Small'){
            this.isMobile = true;
        }
        
        let currentDate = new Date();
        this.today = this.addMinutes(currentDate, 15);
        this.today = this.today.toISOString();
        this.calculateMinEndDate();
    }

    renderedCallback() {
        if (this.minEndDate == undefined && this.startDate) {
            this.calculateMinEndDate();
        }

        if (this.startDate != undefined && this.startDate != null) {
            // it should fire if u have enter start date 
            this.isInputValid();
        }
    }

    isInputValid() {
        let isValid = true;
        this.formattedCurrentDateTime = this.today;
        let inputFields = this.template.querySelectorAll('.validate');
        inputFields.forEach(inputField => {
            if(!inputField.checkValidity()) {
                inputField.reportValidity();
                isValid = false;
                if( (inputField.name == 'startDateInput' || inputField.name == 'endDateInput') && this.isMobile){
                    switch (inputField.name){
                        case 'startDateInput':
                            if(new Date(inputField.value) < new Date(this.today)){
                                this.isInvalidStartDate = true ;
                                this.generateFormattedCurrentDateTime(new Date(this.today));
                                inputField.setCustomValidity('Value must be '+ this.formattedCurrentDateTime +' or later.');
                            }else{
                                inputField.setCustomValidity('');
                            }
                            break;

                        case 'endDateInput':
                            if((new Date(inputField.value) <= new Date(this.startDate)) || (new Date(inputField.value) < new Date(this.today) )){
                                this.isInvalidEndDate = true ;
                                if(new Date(inputField.value) < new Date(this.startDate)){
                                    let currentDate = new Date(this.startDate);
                                    let newDate = this.addMinutes(currentDate, 15);
                                    this.generateFormattedCurrentDateTime(new Date(newDate));
                                    inputField.setCustomValidity('Value must be '+ this.formattedCurrentDateTime +' or later.');
                                }
                            }else{
                                inputField.setCustomValidity('');
                            }
                            break;
                    }
                }
            }
        });
        return isValid;
    }

    generateFormattedCurrentDateTime(inputDate) {
        const currentDate = inputDate;
        const options = {
            year: 'numeric',
            month: 'short',
            day: 'numeric',
            hour: '2-digit',
            minute: '2-digit',
            second: '2-digit',
            hour12: true // Use 12-hour format
        };
        this.formattedCurrentDateTime = currentDate.toLocaleDateString('en-US', options);
    }
   

    updateInputDurationValue() {
        switch (this.duration) {
            case '1 Day':
                this.duration = DURATION_VALUE.DAY;
                break;
            case '7 Days':
                this.duration = DURATION_VALUE.WEEK;
                break;
            case '28 Days':
                this.duration = DURATION_VALUE.MONTH;
                break;
        }
    }

    addMinutes(date, minutes) {
        return new Date(date.getTime() + minutes * 60000);
    }
    

    handleDurationChange(event) {
        this.duration = event.detail.value;
        if (this.duration == DURATION_VALUE.CUSTOM) {
            this.endDate = undefined;
        } else {
            //this.calculateEndDate();
        }
    }

    calculateEndDate() {
        if (this.duration !== DURATION_VALUE.CUSTOM && this.startDate) {
            let result = null;
                result = new Date(this.startDate);
                if (this.duration == DURATION_VALUE.DAY) {
                    result.setDate(result.getDate() + 1);
                }
                else if (this.duration == DURATION_VALUE.WEEK) {
                    result.setDate(result.getDate() + 7);
                }
                else if (this.duration == DURATION_VALUE.MONTH) {
                    result.setDate(result.getDate() + 28);
                }
            
            if (result) {
                result = result.toISOString();
                this.endDate = result;
            }
        }
    }

    handleStartDateChange(event) {
        this.startDate = event.detail.value;
        //this.calculateEndDate();
        this.calculateMinEndDate();
        this.isInputValid();
    }

    handleEndDateChange(event) {
        this.endDate = event.detail.value;
        this.calculateMinEndDate();
        this.isInputValid();
    }

    calculateMinEndDate(){
        if (this.startDate) {
            this.minEndDate = this.addMinutes(new Date(this.startDate), 15);
            this.minEndDate = this.minEndDate.toISOString();
        }
    }

    @api
    validate() {
        if (this.validateFields()) {
            return { isValid: true };
        }
        else {
            // If the component is invalid, return the isValid parameter
            // as false and return an error message.
            let undefinedFields = this.getUndefinedFields();
            return {
                isValid: false,
                errorMessage: 'Please populate the required fields- ' + undefinedFields
            };
        }
    }

    validateFields() {
        if (this.showEndDate) {
            return this.duration && this.startDate && this.endDate;
        } else {
            return this.duration && this.startDate;
        }
    }

    getUndefinedFields() {
        let undefinedFields = [];

        const fields = [
            //SF-6490 : Rename Label from Quoted Duration to Duration
            { value: this.duration === undefined, fieldName: 'Duration' },
            { value: this.startDate === undefined, fieldName: 'Start Date' },
            { value: this.showEndDate == true && this.endDate == undefined, fieldName: 'End Date' }
        ];

        for (const field of fields) {
            if (field.value === true) {
                undefinedFields.push(field.fieldName);
            }
        }

        return undefinedFields.join(', ');
    }

    get showEndDate() {
        return this.duration == DURATION_VALUE.CUSTOM;
    }

    get durationOptions() {
        return [
            { label: DURATION_VALUE.DAY, value: DURATION_VALUE.DAY },
            { label: DURATION_VALUE.WEEK, value: DURATION_VALUE.WEEK },
            { label: DURATION_VALUE.MONTH, value: DURATION_VALUE.MONTH },
            { label: DURATION_VALUE.CUSTOM, value: DURATION_VALUE.CUSTOM }
        ];
    }

    
}