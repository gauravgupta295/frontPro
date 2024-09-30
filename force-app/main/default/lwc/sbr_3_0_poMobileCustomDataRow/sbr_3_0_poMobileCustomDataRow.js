import { LightningElement, api, track } from 'lwc';

const STATUS_VALUES = Object.freeze({
    ACTIVE: "Active",
    INACTIVE: "Inactive",
    DRAFT: "Draft",
    OPEN: 'Open',
    CLOSED: "Closed",
    DELETED: "Deleted",
    ONHOLD: "On-Hold",
    NONE: "None",
    RECEIVED: "Received",
    BACKORDER: "Back Order",
    PARTIALLYRECEIVED: "Partially Received",
    CANCELLED: "Cancelled"
});


export default class Sbr_3_0_poMobileCustomDataRow extends LightningElement {

    @api recordId;
    @track _recordItem;
    hasRendered = false;
    checked = false;
    
    @api
    set check(value) {
        this.checked = value;
    }
    get check() {
        return this.checked;
    }
    renderedCallback() {
        if(!this.hasRendered){
            this.hasRendered = true;
            if (this.recordItem.hasSelectEvent){
                this.refs.rowDiv.classList.remove('disabledSection');
                const handleCLick = (event) => {
                    event.stopPropagation();
                    this.handleClick(this.recordItem);            
                }
                this.refs.rowDiv.addEventListener("click", handleCLick);
            }
            else {
                if(this.recordItem.isRowDisabled){
                    this.refs.rowDiv.classList.add('disabledSection');
                }
            }
        }
    }

    handleClick(recordItem) {
        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                record: recordItem.record
            }
        }));
    }

    handleEditClick(){
        this.dispatchEvent(new CustomEvent('edit',{
            detail: {
                recordId: this.recordItem.recordId
            }
        }));
    }

    @api
    set recordItem(value) {
        if (this._recordItem !== value) {
            this._recordItem = value;            
        }
    }
    get recordItem() {
        return this._recordItem;
    }

    openMenu(event) {
        event.stopPropagation();
    }

    handleMenuClick(event) {
        this.dispatchEvent(new CustomEvent('menuclick', {
            detail: {
                eventName: event.detail.value,
                id: event.currentTarget.dataset.id
            }
        }));
    }

    handleCheckboxChange(event) {
        this.dispatchEvent(new CustomEvent('checkboxchange', {
            detail: {
                checked: event.currentTarget.checked,
                id: event.currentTarget.dataset.id
            }
        }));
    }

    applyStatusButtonBackgroundColor(status) {
        let defaultStatusClass = "color-boxes ";
        let colorClass = "";

        if (status === STATUS_VALUES.ACTIVE) colorClass = "greenColor";
        if (status === STATUS_VALUES.INACTIVE) colorClass = "greyColor";
        if (status === STATUS_VALUES.CLOSED) colorClass = "greyColor";
        if (status === STATUS_VALUES.DRAFT) colorClass = "greyColor";
        if (status === STATUS_VALUES.OPEN) colorClass = "greenColor";
        if (status === STATUS_VALUES.ONHOLD) colorClass = "orangeColor";
        if (status === STATUS_VALUES.NONE) colorClass = "greyColor";
        if (status === STATUS_VALUES.DELETED) colorClass = "redColor";
        if (status === STATUS_VALUES.RECEIVED) colorClass = "blue50Color";
        if (status === STATUS_VALUES.PARTIALLYRECEIVED) colorClass = "paletteRedColor";
        if (status === STATUS_VALUES.BACKORDER) colorClass = "paletteYellowColor";
        if (status === STATUS_VALUES.CANCELLED) colorClass = "darkRedColor";
        return defaultStatusClass + colorClass;
    }

    //Adding as part of FRONT-4592
    get statusButtonBackgroundColour() {
        if (this.recordItem.statusText) {
            return this.applyStatusButtonBackgroundColor(this.recordItem.statusText);
        }
    }


}