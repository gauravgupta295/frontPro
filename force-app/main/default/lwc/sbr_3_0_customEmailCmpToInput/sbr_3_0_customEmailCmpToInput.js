import CallDurationInSeconds from '@salesforce/schema/Task.CallDurationInSeconds';
import { LightningElement ,track ,api} from 'lwc';

export default class Sbr_3_0_customEmailCmpToInput extends LightningElement {

    // To set default value for "To" in email
    @api defaultValueTo;
    @track items = [];
    searchTerm = "";
    blurTimeout;
    boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus";
    _selectedValues = []
    selectedValuesMap = new Map();
    getSelecteValueCount=0;
    mapitem;
    defaultValueErased=false;
    

    get selectedValues() {
        
     console.log(this.defaultValueErased);

       if(this.defaultValueErased==false){
        
            if((this.defaultValueTo!=undefined && this.getSelecteValueCount==0)){
                this._selectedValues.push(this.defaultValueTo);
                this.getSelecteValueCount=this.getSelecteValueCount+1;
            }else if(this.mapitem!=this.defaultValueTo && this.defaultValueTo!=undefined){

                //console.log("ELSE IF ")
            
                    this._selectedValues.push(this.defaultValueTo);
                    this._selectedValues=[...new Set(this._selectedValues)];

                
            }
        }
       

        if(this.mapitem==this.defaultValueTo && this.defaultValueTo!=undefined){
             this.defaultValueErased=true;
             
        }

         

        return this._selectedValues;
    }


    set selectedValues(value) {

       
        this._selectedValues =value;
     

        const selectedValuesEvent = new CustomEvent("selection", { detail: { selectedValues: this._selectedValues} });
        this.dispatchEvent(selectedValuesEvent);
    }

    handleInputChange(event) {
        event.preventDefault();
        if (event.target.value.length < 3) {
            return;
        }

        //this.searchTerm = event.target.value;
        //let searchTerm = this.template.querySelector('input.input').value;

        /*search({ searchString: event.target.value })
            .then((result) => {
                console.log("Result", result);
                this.items = result;
                if (this.items.length > 0) {
                    this.boxClass =
                        "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus slds-is-open";
                }
            })
            .catch((error) => {
                console.error("Error:", error);
            });*/
    }

    handleBlur() {
        console.log("In onBlur");
        // eslint-disable-next-line @lwc/lwc/no-async-operation
        this.blurTimeout = setTimeout(() => {
            this.boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus";
            const value = this.template.querySelector('input.input').value
            
          
                if (value !== undefined && value != null && value !== "") {
                    console.log("in if cond");
                    this.selectedValuesMap.set(value, value);
                    this.selectedValues = [...this.selectedValuesMap.keys()];
                }
             
            console.log("this.selectedValues***", this.selectedValues);
            this.template.querySelector('input.input').value = "";
        }, 300);
    }

    get hasItems() {
        return this.items.length;
    }

    handleKeyPress(event) {
        if (event.keyCode === 13) {
            event.preventDefault(); // Ensure it is only this code that runs

            const value = this.template.querySelector('input.input').value;
            if (value !== undefined && value != null && value !== "") {
                this.selectedValuesMap.set(value, value);
                this.selectedValues = [...this.selectedValuesMap.keys()];
            }
            this.template.querySelector('input.input').value = "";
        }
    }

    handleRemove(event) {
        const item = event.target.label;
        console.log("item", item);
        this.mapitem =item;
        this.selectedValuesMap.delete(item);
        this.selectedValues = [...this.selectedValuesMap.keys()];
     
        // Event to capture in parent
        const handleRemoveConst = new CustomEvent("handleremove", {
            detail: {selecteValues:this.selectedValues,removedItem:item}
          });
        // Dispatch event
        this.dispatchEvent(handleRemoveConst);

      
    }

    onSelect(event) {
        this.template.querySelector('input.input').value = "";
        console.log("In onSelect");
        let ele = event.currentTarget;
        let selectedId = ele.dataset.id;
        console.log("selectedId", selectedId);
        let selectedValue = this.items.find((record) => record.Id === selectedId);
        this.selectedValuesMap.set(selectedValue.Email, selectedValue.Name);
        this.selectedValues = [...this.selectedValuesMap.keys()];

        //As a best practise sending selected value to parent and inreturn parent sends the value to @api valueId
        let key = this.uniqueKey;
        const valueSelectedEvent = new CustomEvent("valueselect", {
            detail: { selectedId, key }
        });
        this.dispatchEvent(valueSelectedEvent);

        if (this.blurTimeout) {
            clearTimeout(this.blurTimeout);
        }
        this.boxClass = "slds-combobox slds-dropdown-trigger slds-dropdown-trigger_click slds-has-focus";
    }

    @api reset() {
        this.selectedValuesMap = new Map();
        this.selectedValues = [];
    }

    @api validate() {
        this.template.querySelector('input').reportValidity();
        const isValid = this.template.querySelector('input').checkValidity();
        return isValid;
    }

    @api addContactEmailAsToEmail(contactValue){

        if (contactValue !== undefined && contactValue != null && contactValue !== "") {
            this.selectedValuesMap.set(contactValue, contactValue);
            this.selectedValues = [...this.selectedValuesMap.keys()];
        }
    }


}