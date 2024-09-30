import { LightningElement, api, track } from "lwc";
import cancelLineItemDesktopTemplate from "./sbr_3_0_cancelLineItemsCmpDesktop.html";
import cancelLineItemMobileTemplate from "./sbr_3_0_cancelLineItemsCmpMobile.html";
import LABELS from "c/sbr_3_0_customLabelsCmp";

export default class Sbr_3_0_cancelLineItemsCmp extends LightningElement {
  @api recordId;
  @api isMobile;
  @api cancelRows;
  showCancelScreen = false;
  label = LABELS;
  //FRONT- 7654,7655 Start
  finalList = [];
  allChecked = true;
  allnotCheckd = false;
  showCancelReservation = false;
  @track selectedRecordIds = [];
  callCancelCmp = false;
  showCancelItems = true;
  disableButton = false;
  @track showRemove = false;
  @api recordsLength;
  @api isRental;
  showNormalMsg = true;
  allRecordsSelected = false;
  showCancelResButton = false;
  singleItemCancel = false;
  mobileProps = {
    zIndex: 9004,
    fullScreen: true
  };
  showScreen = false;
  //FRONT- 7654,7655 End

  render() {
    if (this.cancelRows != null) {
      if (this.cancelRows.length === 1) {
        this.showCancelScreen = false;
      } else if (this.cancelRows.length > 1) {
        this.showCancelScreen = true;
      }
    }

    if (this.isMobile) {
      return cancelLineItemMobileTemplate;
    } else {
      if (!this.isRental && this.cancelRows.length > 1) {
        this.allnotCheckd = true;
      }

      return cancelLineItemDesktopTemplate;
    }
  }
  //FRONT- 7654,7655 Start
  connectedCallback() {
    if (!this.isRental) {
      this.allChecked = false;
    } else if (this.isRental && this.cancelRows.length === this.recordsLength) {
      this.allRecordsSelected = true;
      this.showCancelResButton = true;
      this.allnotCheckd = false;
      this.singleItemCancel = true;
    } else if (this.isRental) {
      this.allChecked = false;
    }
    // FRONT-8694
    if(this.isMobile) { 
      const cancelItemEvent = new CustomEvent("componentload", {
        bubbles:true, 
        composed: true
      });
      this.dispatchEvent(cancelItemEvent);
    }
  }
  //FRONT- 7654,7655 End

  closeModal() {
    const cancelItemEvent = new CustomEvent("handleitemacancelction", {}); // FRONT-8694
    this.dispatchEvent(cancelItemEvent);
    const closeCancelItemEvent = new CustomEvent("handleclosecancelmodel", {
      bubbles:true,
      composed:true
    });
      this.dispatchEvent(closeCancelItemEvent);
  }

  handleCancelClick() {
    this.dispatchEvent(
      new CustomEvent("handlecancelaction", {
        detail: {
          itemsToRemove: this.cancelRows
        }
      })
    );
    this.closeModal();
  }

  //FRONT-7655 START
  handleAllSelected(event) {
    let letItems = [];
    let selectedRows = this.template.querySelectorAll(
      'lightning-input[data-key="firstColumnCheckbox"]'
    );

    selectedRows.forEach((row) => {
      if (row.type === "checkbox") {
        row.checked = event.target.checked;
        if (row.checked) {
          letItems.push(row);
        }
        //row.checked = true;
      }
    });
    //FRONT-7655 : Added Check for isRental START
    if (this.isRental) {
      if (letItems.length === this.recordsLength) {
        this.showRemove = false;
        this.allChecked = true;
        this.allnotCheckd = false;
        this.allRecordsSelected = true;
      } else if (letItems.length === this.cancelRows.length) {
        this.showRemove = false;
        this.allChecked = false;
        this.allRecordsSelected = false;
      } else {
        this.showRemove = true;
        this.allChecked = false;
        this.allnotCheckd = true;
        this.allRecordsSelected = false; // set true for keeping the message when any item is deselected
      }

      if (letItems.length === 0) {
        this.showRemove = false;
        this.allChecked = true;
        this.allRecordsSelected = false;
      }
    } else {
      if (letItems.length === this.recordsLength) {
        this.showRemove = false;
        this.allRecordsSelected = false;
        this.allChecked = false;
      } else {
        this.showRemove = false;
        this.allChecked = false;
      }

      if (letItems.length === 0) {
        this.showRemove = false;
        this.allChecked = true;
      }
    }
    //FRONT-7655 : Added Check for isRental END
  }

  handleSingleCheckboxSelect(event) {
    const boxes = this.template.querySelectorAll(
      'lightning-input[data-key="singleSelectColumnCheckbox"]'
    );

    boxes.forEach((box) => (box.checked = event.target.name === box.name));
    if (boxes.length === this.recordsLength) {
      this.allChecked = false;
      this.allnotCheckd = true;
    }
  }

  handleCheckboxSelect(event) {
    let selectedRows = this.template.querySelectorAll(
      'lightning-input[data-key="firstColumnCheckbox"]'
    );

    let allSelected = true;
    selectedRows.forEach((currentItem) => {
      if (!currentItem.checked && currentItem.type === "checkbox") {
        allSelected = false;
      }
    });

    if (!this.isMobile) {
      let selectedRow = this.template.querySelector(
        'lightning-input[data-key="allCheckbox"]'
      );
      if (allSelected) {
        selectedRow.checked = true;
        this.allChecked = true;
        this.allnotCheckd = false;
      } else {
        selectedRow.checked = false;
        this.allChecked = false;
        this.allnotCheckd = true;
      }
    }

    //Start FRONT-7656
    if (this.isMobile) {
      if (allSelected) {
        this.allChecked = true;
        this.allnotCheckd = false;
      } else {
        this.allChecked = false;
        this.allnotCheckd = true;
      }
    }
    //End FRONT-7656
    
    let checkedRows = [];
    selectedRows.forEach((currentItem) => {
      if (currentItem.checked && currentItem.type === "checkbox") {
        checkedRows.push(currentItem);
      }
    });
    //FRONT-7655 : Added Check for isRental START
    if (this.isRental) {
      if (
        checkedRows.length < this.cancelRows.length &&
        checkedRows.length !== 0
      ) {
        this.showRemove = true;
        this.allChecked = false;
        this.allnotCheckd = true;
        this.allRecordsSelected = false; // set true for keeping the message when any item is deselected
      } else if (checkedRows.length === 0) {
        this.showRemove = false;
        this.allChecked = true;
        this.allRecordsSelected = false;
      } else if (
        checkedRows.length === this.cancelRows.length &&
        checkedRows.length !== this.recordsLength
      ) {
        this.showRemove = false;
        this.allRecordsSelected = false;
        this.allChecked = false;
      } else {
        this.showRemove = false;
        this.allRecordsSelected = true;
      }
    } else {
      if (checkedRows.length < this.recordsLength && checkedRows.length !== 0) {
        this.showRemove = true;
        this.allChecked = false;
      } else if (checkedRows.length === 0) {
        this.showRemove = false;
        this.allChecked = true;
      } else if (checkedRows.length === this.cancelRows.length) {
        this.showRemove = false;
        this.allChecked = false;
      } else {
        this.showRemove = false;
      }
    }
    //FRONT-7655 : Added Check for isRental END
  }

  getAllSelectedRecord() {
    this.finalList = [];
    let firstColumnSelectedRecord = [];

    if (!this.isMobile) {
      let firstColumnCheckboxRows = this.template.querySelectorAll(
        'lightning-input[data-key="firstColumnCheckbox"]'
      );
      firstColumnCheckboxRows.forEach((row) => {
        if (row.type === "checkbox" && row.checked) {
          firstColumnSelectedRecord.push(row.dataset.id);
          this.finalList.push(
            this.cancelRows.find((item) => item.Id === row.dataset.id)
          );
        }
      });
      if (this.recordsLength === this.finalList.length) {
        this.allChecked = false;
        this.allnotCheckd = true;
      }
    } else {
      var elems = this.template.querySelectorAll(
        'lightning-input[data-key="firstColumnCheckbox"]'
      );
      elems.forEach((element, index) => {
        if (element.checked) {
          firstColumnSelectedRecord.push(element.value);
        }
      });
      this.finalList = this.cancelRows.filter((row) =>
        firstColumnSelectedRecord.includes(row.Id)
      );
    }

    this.dispatchEvent(
      new CustomEvent("handlecancelaction", {
        detail: {
          itemsToRemove: this.finalList
        }
      })
    );
    this.closeModal();
  }

  cancelReservation() {
    this.callCancelCmp = true;
    this.showCancelItems = false;
  }
  //FRONT-7655 END
  //START: FRONT-7654
  handleMobileCheckbox(event) {
    let isChekced = false;
    let selectedRows = this.template.querySelectorAll(
      'lightning-input[data-key="firstColumnCheckbox"]'
    );
    selectedRows.forEach((currentItem) => {
      if (currentItem.checked) {
        isChekced = true;
        return;
      }
    });
    this.disableButton = !isChekced;
  }
  //END: FRONT-7654
  //Started for FRONT-1946
  handleCloseCancel() {
    this.callCancelCmp = false;
  }
  //Ended for FRONT-1946
}