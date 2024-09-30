import { LightningElement, api, track } from "lwc";

export default class Sbr_3_0_GenericDataTableMobile extends LightningElement {
  @api columns;
  @api records;
  @api hideCheckboxColumn = false;
  _selectedRows = [];
  @api maxRowSelection = 1;
  @track finalData = [];

  @api
  set selectedRows(value) {
    this._selectedRows = value;
  }

  get selectedRows() {
    return this._selectedRows;
  }

  passRowButtonEvent(event) {
    const tableButtonEvent = new CustomEvent("tablebuttonevent", {
      detail: {
        recordId: event.detail.recordId,
        recordValue: event.detail.recordValue
      }
    });
    this.dispatchEvent(tableButtonEvent);
  }

  getSelectedRecords(event) {
    let filteredRecords = [];
    if (this.maxRowSelection === 1) {
      filteredRecords.push(event.detail.selectedRecord);
    } else {
      if (event.detail.isSelected) {
        this.selectedRows.push(event.detail.selectedRecord);
        filteredRecords = this.selectedRows;
      } else {
        filteredRecords = this.selectedRows.filter((record) => {
          return record.id !== event.detail.selectedRecord.id;
        });
        this.selectedRows = filteredRecords;
      }
    }
    const customEvent = new CustomEvent("rowselection", {
      detail: {
        selectedRows: filteredRecords
      }
    });
    this.dispatchEvent(customEvent);
  }
}