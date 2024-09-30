import { LightningElement, api, wire, track } from 'lwc';
import { CloseActionScreenEvent } from 'lightning/actions';
import getPOLineItems from '@salesforce/apex/SBR_3_0_PurchaseOrderLineItems.getPOLineItems';
import getProductRecord from '@salesforce/apex/SBR_3_0_CreatePOLineItemController.getProductRecord';
import createNewPOLineItem from '@salesforce/apex/SBR_3_0_CreatePOLineItemController.createNewPOLineItem';
import createNewPOLineItemFromProduct from '@salesforce/apex/SBR_3_0_CreatePOLineItemController.createNewPOLineItemFromProduct';
import getRatingPicklistValues from '@salesforce/apex/SBR_3_0_CreatePOLineItemController.getPicklistValues';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { notifyRecordUpdateAvailable } from 'lightning/uiRecordApi';
import PO_CSS from '@salesforce/resourceUrl/sbr_3_0_PO_lwcCSS';
import { loadStyle } from 'lightning/platformResourceLoader';
import FORM_FACTOR from '@salesforce/client/formFactor';
const SMALL_FORM_FACTOR = "Small";

const FIELDS = ['Purchase_Order__c.Status__c', 'Purchase_Order__c.Company_Code__c', 'Purchase_Order__c.Type__c']
import { getRecord, getFieldValue } from 'lightning/uiRecordApi';
const columns = [
  { label: 'Part/Item#', fieldName: "Item_Number__c" },
  { label: 'Stock/Vendor', fieldName: 'Stock_class__c' },
  { label: 'PME', fieldName: 'Product_Type__c' },
  { label: 'Item Description', fieldName: 'Name' },
  { label: 'Search Word', fieldName: 'Search_Word__c' },
  { label: 'Vendor', fieldName: 'Vendor_Number1__c' }
];

export default class SBR_3_0_createPOLineItem extends LightningElement {
  @api recordId;
  quantity = 1;
  nextModal = false;
  openModal = true;
  columns = columns;
  poData = [];
  poLineItemRecord = {};
  @api updatedQuantity;
  @api purchaseOrderId;
  @api productID;
  itemNumber = '';
  description = '';
  unitCost = '';
  stockClass = '';
  unitMeasure = [];
  POunit = '';
  disableSave = true;
  typeValue = '';
  ItemType = '';
  companyCode;
  regularPrice;
  showSpinner = false;
  @api productCost;

  get options() {
    return [
      { label: 'P', value: 'P' },
      { label: 'M', value: 'M' },
    ];
  }
  @wire(getRecord, { recordId: '$recordId', fields: FIELDS })
  wiredRecord({ error, data }) {
    if (data) {
      this.companyCode = data.fields.Company_Code__c.value;
      this.poRecordType = data.fields.Type__c.value;
    } else if (error) {
      this.error = error;
    }
  }

  get isMobileView() {
    return FORM_FACTOR === SMALL_FORM_FACTOR;
  }

  handleTypeChange(event) {
    this.typeValue = event.detail.value;
    this.handleValidation();
  }

  handleNumberChange(event) {
    this.itemNumber = event.target.value;
    this.handleValidation();
  }
  handleDescriptionChange(event) {
    this.description = event.target.value;
    this.handleValidation();
  }
  handleCostChange(event) {
    this.unitCost = event.target.value;
    this.regularPrice = (this.unitCost * 1.65).toFixed(2);
    this.handleValidation();
  }
  handleClassChange(event) {
    this.stockClass = event.target.value;
    this.handleValidation();
  }
  handlePickListChange(event) {
    this.POunit = event.target.value;
    this.handleValidation();
  }

  // Wire getRatingPicklistValues function from Apex controller to the component
  @wire(getRatingPicklistValues, {})
  // Define a wired property for rating picklist values
  wiredRatingPicklistValues({ error, data }) {
    // If data is returned from the wire function
    if (data) {
      // Map the data to an array of options
      this.unitMeasure = data.map(option => {
        return {
          label: option.label,
          value: option.value
        };
      });
      this.POunit = this.unitMeasure[0].value;
    }
    // If there is an error
    else if (error) {
      // Log the error to the console
      console.error(error);
    }
    if (this.unitMeasure.values == 'EA') {
      this.POunit = this.unitMeasure.values;
    }
  }

  handleValidation() {
    if (this.itemNumber != '' && this.description != '' && this.stockClass != '' && this.unitCost != '' && this.POunit != '' && this.typeValue != '') {
      if (this.unitCost < 0) {
        const inputField = this.template.querySelector('lightning-input[data-name="Itemcost"]');
        const inputValue = parseFloat(this.unitCost);
        if (inputValue < 0) {
          inputField.setCustomValidity('Item cost cannot be negative.');
        } else {
          inputField.setCustomValidity('');
          this.unitCost = inputValue;
        }
        inputField.reportValidity();
        this.disableSave = true;
      } else {
        this.disableSave = false;
      }
    } else {
      this.disableSave = true;
    }
  }

  handleNext() {
    this.showSpinner = true;
    getProductRecord({ itemNumber: this.itemNumber, description: this.description, stockClass: this.stockClass, companyCode: this.companyCode })
      .then((result) => {
        this.poData = result;
        this.showSpinner = false;
      })
      .catch((error) => {
        this.error = result;
        this.showSpinner = false;
      });
    this.nextModal = true;
    this.openModal = false;
  }

  connectedCallback() {
    if (this.openModal == false)
      this.openModal = true;
  }

  renderedCallback() {
    if (!this.isCSSLoaded) {
      loadStyle(this, PO_CSS + '/POlwc.css').then(() => {
        this.isCSSLoaded = true;
      }).catch(error => {
        console.log('error loading CSS');
      });
    }
  }

  handleCancel() {
    this.openModal = !this.openModal;
    this.dispatchEvent(new CustomEvent("close"))
  }

  handleBack() {
    this.nextModal = false;
    this.openModal = true;
  }

  decreaseQuantity(event) {
    if (this.quantity > 1) {
      this.quantity--;
      const rowId = this.recordId;
    }
  }

  increaseQuantity(event) {
    this.quantity++;
    if (this.quantity === null) {
      this.quantity = 1;
    }
    const rowId = this.recordId;
  }

  changeQuantity(event) {
    this.quantity = event.detail.value;
    if (this.quantity === null) {
      this.quantity = 0;
    }
  }

  handleProduct(event) {
    const selectedRows = event.detail.selectedRows;
    this.productID = selectedRows[0].Id;
    this.productCost = selectedRows[0].Last_Cost__c;
  }

  handleRadioButtonChange(event) {
    const isChecked = event.target.dataset.id;
    this.productID = isChecked;
    this.productCost = event.target.dataset.cost;
  }


  showToast(title, message, variant) {
    const event = new ShowToastEvent({
      title: title,
      message: message,
      variant: variant
    });
    this.dispatchEvent(event);
  }

  async handleSave(event) {
    let isSelfValidated = true;
    isSelfValidated = [
      ...this.template.querySelectorAll("lightning-input")
    ].reduce((validSoFar, inputField) => {
      inputField.reportValidity();
      return validSoFar && inputField.checkValidity();
    }, true);

    if (!isSelfValidated) {
      this.showToast('Error while adding to Purchase Order', 'Please enter a valid value equal to or greater than 1', 'error');
    } else {
      if (this.productID == '' || this.productID == null || this.productID == undefined) {
        createNewPOLineItem({ recordId: this.recordId, itemNumber: this.itemNumber, unitCost: this.unitCost, description: this.description, stockClass: this.stockClass, quantityvalue: this.quantity, POunit: this.POunit, typeValue: this.typeValue })
          .then(result => {
            this.dispatchEvent(
              new ShowToastEvent({
                message: 'PO Line Item(s) added Successfully',
                title: 'Success',
                variant: 'Success'
              })
            );
            this.dispatchEvent(new CustomEvent("close"));
            this.nextModal = false;
          })
          .catch(error => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error while adding to Purchase Order',
                message: error.body.message,
                variant: 'error'
              })
            );
          });
      } else {

        createNewPOLineItemFromProduct({ recordId: this.recordId, productRecordId: this.productID, quantityvalue: this.quantity, unitCost: this.productCost })
          .then(result => {
            this.dispatchEvent(
              new ShowToastEvent({
                message: 'PO Line Item(s) added Successfully',
                title: 'Success',
                variant: 'Success'
              })
            );
            this.dispatchEvent(new CustomEvent("close"));
            this.nextModal = false;
          })
          .catch(error => {
            this.isLineItemLoaded = false;
            this.errorMessage = error.body.message; // Display Apex error message
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error while adding to Purchase Order',
                message: error.body.message,
                variant: 'error'
              })
            );
          });
      }
    }
  }

  async handleSaveMobile(event) {
    let isSelfValidated = true;
    isSelfValidated = [
      ...this.template.querySelectorAll("lightning-input")
    ].reduce((validSoFar, inputField) => {
      inputField.reportValidity();
      return validSoFar && inputField.checkValidity();
    }, true);

    if (!isSelfValidated) {
      this.showToast('Error while adding to Purchase Order', 'Please enter a valid value equal to or greater than 1', 'error');
    } else {
      if (this.productID == '' || this.productID == null || this.productID == undefined) {
        createNewPOLineItem({ recordId: this.recordId, itemNumber: this.itemNumber, unitCost: this.unitCost, description: this.description, stockClass: this.stockClass, quantityvalue: this.quantity, POunit: this.POunit, typeValue: this.typeValue })
          .then(result => {
            this.dispatchEvent(
              new ShowToastEvent({
                message: 'PO Line Item(s) added Successfully',
                title: 'Success',
                variant: 'Success'
              })
            );
            this.dispatchEvent(new CustomEvent("close"));
            this.nextModal = false;
          })
          .catch(error => {
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error while adding to Purchase Order',
                message: error.body.message,
                variant: 'error'
              })
            );
          });
      } else {
        createNewPOLineItemFromProduct({ recordId: this.recordId, productRecordId: this.productID, quantityvalue: this.quantity, unitCost: this.productCost })
          .then(result => {
            this.dispatchEvent(
              new ShowToastEvent({
                message: 'PO Line Item(s) added Successfully',
                title: 'Success',
                variant: 'Success'
              })
            );
            this.dispatchEvent(new CustomEvent("close"));
            this.nextModal = false;
          })
          .catch(error => {
            this.isLineItemLoaded = false;
            this.errorMessage = error.body.message; // Display Apex error message
            this.dispatchEvent(
              new ShowToastEvent({
                title: 'Error while adding to Purchase Order',
                message: error.body.message,
                variant: 'error'
              })
            );
          });
      }
    }
  }
}