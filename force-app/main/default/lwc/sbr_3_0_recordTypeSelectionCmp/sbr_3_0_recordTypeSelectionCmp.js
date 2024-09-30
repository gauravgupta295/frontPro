import { LightningElement, wire, api } from "lwc";
import { getObjectInfo } from "lightning/uiObjectInfoApi";
import { getRecords } from "lightning/uiRecordApi";
import { isEmpty, isUndefinedOrNull, Logger } from "c/sbr_3_0_frontlineUtils";
const logger = Logger.create(false);
const RECORD_TYPE_FIELDS = [
  "RecordType.Id",
  "RecordType.Name",
  "RecordType.Description"
];
const SUCCESS_CODE_200 = 200;
const RECORD_SELECTION_ORIGIN = "RecordTypeSelection";
export default class Sbr_3_0_RecordSelectionCmp extends LightningElement {
  @api
  objectApiName;
  _recordTypesInfo;
  accountTypeOptions;
  _parameterObject;
  _selectedRecordType;
  _selectedRecordTypeId;
  _recordTypeIds;
  @wire(getObjectInfo, {
    objectApiName: "$objectApiName"
  })
  objectInfo({ error, data }) {
    if (data) {
      this._recordTypesInfo = data.recordTypeInfos;
      this.getEligibleRecordTypes(Object.values(this._recordTypesInfo));
      this.buildParametersForRecordTypeDetails();
    } else if (error) {
      logger.error(error);
    }
  }

  getEligibleRecordTypes(recordTypeInfos) {
    const recordTypeIds = [];
    for (let recordType of recordTypeInfos) {
      if (recordType.available) {
        if (
          isUndefinedOrNull(this._selectedRecordTypeId) &&
          recordType.defaultRecordTypeMapping
        ) {
          this._selectedRecordTypeId = recordType.recordTypeId;
        }
        recordTypeIds.push(recordType.recordTypeId);
      }
    }
    this._recordTypeIds = recordTypeIds;
  }

  buildParametersForRecordTypeDetails() {
    this._parameterObject = [
      {
        recordIds: this._recordTypeIds,
        fields: RECORD_TYPE_FIELDS
      }
    ];
  }

  @wire(getRecords, {
    records: "$_parameterObject"
  })
  wiredRecordTypes({ error, data }) {
    if (data) {
      this.buildRecordTypeSelectionData(data.results);
    } else if (error) {
      logger.error(error);
    }
  }

  buildRecordTypeSelectionData(recordTypeResults) {
    let recordTypeOptions = [];

    for (let recordTypeResult of recordTypeResults) {
      if (recordTypeResult.statusCode !== SUCCESS_CODE_200) {
        continue;
      }
      recordTypeOptions.push(this.buildRecordType(recordTypeResult.result));
    }
    this.sortRecordTypeSelectionData(recordTypeOptions);
    this.setSelectedRecordTypeOnLoad(recordTypeOptions);
    this.accountTypeOptions = recordTypeOptions;
  }

  buildRecordType(result) {
    let self = this;
    let recordType = {
      label: result.fields.Name.value,
      value: result.fields.Name.value,
      id: result.fields.Id.value,
      description: result.fields.Description.value,
      get selected() {
        return self._selectedRecordTypeId === result.fields.Id.value;
      }
    };
    return recordType;
  }

  sortRecordTypeSelectionData(recordTypeOptions) {
    recordTypeOptions.sort((firstEle, secondEle) => {
      if (firstEle.selected > secondEle.selected) {
        return -1;
      }
      return 1;
    });
  }

  setSelectedRecordTypeOnLoad(recordTypeOptions) {
    this._selectedRecordType = recordTypeOptions.filter(
      (recordType) => recordType.id === this._selectedRecordTypeId
    )[0];
  }
  handleRadioChange(event) {
    const selectedRecordTypeId = event.target.value;
    this._selectedRecordType = this.accountTypeOptions.filter((recordType) => {
      return selectedRecordTypeId === recordType.id;
    })[0];
    this._selectedRecordTypeId = this._selectedRecordType.id;
  }

  handleCancelClick(event) {
    event.stopPropagation();
    this.dispatchEvent(new CustomEvent("recordtypeclose"));
  }

  handleNextClick(event) {
    event.stopPropagation();
    const recordType = Object.assign({}, this._selectedRecordType);
    this.dispatchEvent(
      new CustomEvent("recordtypesubmit", {
        detail: {
          recordType,
          origin: RECORD_SELECTION_ORIGIN
        }
      })
    );
  }

  get recordTypeHeader() {
    return `New ${this.objectApiName}`;
  }

  get isLoading() {
    return isEmpty(this.accountTypeOptions);
  }
}