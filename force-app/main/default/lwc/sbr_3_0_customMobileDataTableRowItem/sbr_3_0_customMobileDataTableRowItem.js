import { LightningElement, api } from "lwc";

export default class Sbr_3_0_customMobileDataTableRowItem extends LightningElement {
  _record;
  @api
  get record() {
    return this._record;
  }

  set record(value) {
    this._record = Object.assign({}, value);
    this._record.Id = this._record.Id || this._record.id;
  }
  @api column;
  @api hideCheckboxColumn = false;
  @api maxRowSelection = 1;
  @api selectedRows = [];

  get getCellValue() {
    return this.record[this.column.fieldName];
  }
  get getCellLabel() {
    return this.column.label;
  }
  get getCellType() {
    return this.column.type;
  }
  get getCellClass() {
    return this.column.cellAttributes?.class + " " + "asset-info";
  }
  get headerCell() {
    return this.column.cellAttributes?.headerColumn;
  }
  get singleSelection() {
    return this.maxRowSelection === 1;
  }
  get hasActions() {
    return this.column.type === "action";
  }
  get getActions() {
    return this.column.typeAttributes.rowActions;
  }
  get isButton() {
    return this.column.type === "button";
  }
  get getButtonOnClick() {
    return this.column.typeAttributes.onClick;
  }
  get getButtonName() {
    return this.column.typeAttributes.name;
  }

  get isSelected() {
    return this.selectedRows.includes(this.record.Id) ? true : false;
  }

  rowSelection(event) {
    const customEvent = new CustomEvent("rowselection", {
      detail: {
        selectedRecord: this.record,
        isSelected: event.target.checked
      }
    });
    this.dispatchEvent(customEvent);
  }

  buttonPress() {
    const rowButtonEvent = new CustomEvent("rowbuttonevent", {
      detail: {
        recordId: this.record.id,
        recordValue: this.record[this.column.fieldName]
      }
    });
    this.dispatchEvent(rowButtonEvent);
  }
}