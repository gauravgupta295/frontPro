import { LightningElement, api } from 'lwc';

export default class Sbr_3_0_poMobileCustomDataTable extends LightningElement {

    @api recordList = [];

    // Follow properties/structure below to create array or records and pass from parent component.
    _records = [
        {
            rowNumber: 0,
            recordId: '', // required
            record: {}, //required
            hasAttributes: false,
            attributes:
            {
                attribute1: '',
                attribute2: '',
                attribute3: '',
            },
            hasButtonsMenu: false,
            menuItems: [
                {
                    label: 'menu1',
                    value: 'menu1'
                }
            ],
            hasHeader: true,
            isHeaderLink: false,
            isEditEnabled: false,
            url: {
                link: '',
                target: '_blank',
                label: '',
                value: ''
            },
            headerText: '',
            hasStatus: true,
            statusText: '',
            hasSelectEvent: false,
            isRowDisabled: false,
            hasNavigation: false,
            hasCheckbox: false,
            isCheckboxChecked: false,
            navigationURL: '',
            //required
            columns: [
                {
                    key: 0,
                    isVisible: true,
                    isURL: false,
                    url: {
                        link: '',
                        target: '_blank',
                        label: '',
                        value: ''
                    },
                    type: 'text', // required
                    value: '', // required
                    label: 'Name', // required
                    attribute1: '',
                    attribute2: '',
                    attribute3: ''
                }
            ]
        }
    ]

    set records(value) {
        if (this._records !== value) {
            this._records = value;
        }
    }
    get records() {
        return this._records;
    }
    @api
    set checkAll(value) {
        this.template.querySelectorAll('c-sbr_3_0_po-mobile-custom-data-row').forEach(item => {
            item.check = value;
        });
    }
    get checkAll() {
        this.isSelectAllChecked = [...this.template.querySelectorAll('c-sbr_3_0_po-mobile-custom-data-row')]
            .reduce((isSelectAll, dt) => {
                return isSelectAll && dt.check;
            }, true);
    }

    @api refreshRecords(records) {
        this.recordList = records;
        this.createRecords();
    }

    connectedCallback() {
        this.createRecords();
    }

    createRecords() {
        this._records = [];
        if (this.recordList && this.recordList.length > 0) {
            this.recordList.forEach(element => {
                let rowItem = {};
                rowItem.rowNumber = element.rowNumber;
                rowItem.recordId = element.recordId;
                rowItem.record = element.record;
                if (element.hasOwnProperty('hasAttributes') && element.hasAttributes == true && element.attributes) {
                    rowItem.hasAttributes = element.hasAttributes;
                    attributes = {};
                    attributes.attribute1 = (element.attributes.attribute1) ? element.attributes.attribute1 : '';
                    attributes.attribute2 = (element.attributes.attribute2) ? element.attributes.attribute2 : '';
                    attributes.attribute3 = (element.attributes.attribute3) ? element.attributes.attribute3 : '';
                    rowItem.attributes = attributes;
                }
                else {
                    rowItem.hasAttributes = false;
                    rowItem.attributes = {};
                }
                if (element.hasOwnProperty('hasButtonsMenu') && element.hasButtonsMenu == true && element.menuItems) {
                    rowItem.hasButtonsMenu = element.hasButtonsMenu;
                    let menuItems = [];

                    if (element.menuItems && element.menuItems.length > 0) {
                        element.menuItems.forEach(x => {
                            let menuItem = {};
                            menuItem.label = x.label;
                            menuItem.value = x.value;
                            menuItems.push(menuItem);
                        })
                    }

                    rowItem.menuItems = menuItems;
                }
                else {
                    rowItem.hasButtonsMenu = false;
                    rowItem.menuItems = {};
                }
                if (element.hasOwnProperty('hasHeader') && element.hasHeader == true) {
                    rowItem.hasHeader = element.hasHeader;
                    rowItem.headerText = element.headerText;
                }
                else {
                    rowItem.hasHeader = false;
                    rowItem.headerText = '';
                }
                if (element.hasOwnProperty('isHeaderLink') && element.isHeaderLink == true) {
                    if (element.hasOwnProperty('isEditEnabled') && element.isEditEnabled == true) {
                        rowItem.isHeaderLink = element.isHeaderLink;
                        rowItem.isEditEnabled = element.isEditEnabled;
                    }
                    else {
                        rowItem.isHeaderLink = element.isHeaderLink;
                        let url = {};
                        url.link = element.url.link;
                        url.target = element.url.target;
                        url.label = element.url.label;
                        url.value = element.url.value;
                        rowItem.url = url;
                    }
                }
                else {
                    rowItem.isHeaderLink = false;
                }
                if (element.hasOwnProperty('hasStatus') && element.hasStatus == true) {
                    rowItem.hasStatus = element.hasStatus;
                    rowItem.statusText = element.statusText;
                }
                else {
                    rowItem.hasStatus = false;
                    rowItem.statusText = '';
                }
                if (element.hasOwnProperty('hasSelectEvent') && element.hasSelectEvent == true) {
                    rowItem.hasSelectEvent = element.hasSelectEvent;
                }
                else {
                    rowItem.hasSelectEvent = false;
                }
                if (element.hasOwnProperty('isRowDisabled') && element.isRowDisabled == true) {
                    rowItem.isRowDisabled = element.isRowDisabled;
                }
                else {
                    rowItem.isRowDisabled = false;
                }
                if (element.hasOwnProperty('hasNavigation') && element.hasNavigation == true) {
                    rowItem.hasNavigation = element.hasNavigation;
                    rowItem.navigationURL = element.navigationURL;
                }
                else {
                    rowItem.hasNavigation = false;
                    rowItem.navigationURL = '';
                }
                if (element.hasOwnProperty('hasCheckbox') && element.hasCheckbox == true) {
                    rowItem.hasCheckbox = element.hasCheckbox;
                }
                else {
                    rowItem.hasCheckbox = false;
                }
                if (element.hasOwnProperty('isCheckboxChecked') && element.isCheckboxChecked == true) {
                    rowItem.isCheckboxChecked = element.isCheckboxChecked;
                }
                else {
                    rowItem.isCheckboxChecked = false;
                }
                let columns = [];
                if (element.columns && element.columns.length > 0) {
                    element.columns.forEach(col => {
                        let column = {};
                        if (col.label && col.type) {
                            column.key = col.key + '_' + element.recordId;
                            column.isVisible = (col.hasOwnProperty('isVisible') && col.isVisible == true) ? col.isVisible : true;
                            column.isURL = (col.type.toUpperCase() === 'URL') ? true : false;
                            if (column.isURL === true) {
                                let url = {};
                                url.link = col.url.link;
                                url.target = col.url.target;
                                url.label = col.url.label;
                                url.value = col.url.value;
                                column.url = url;
                            }
                            column.type = col.type;
                            column.value = (col.value == null || col.value == '') ? '-' : col.value;
                            column.label = col.label;
                            column.attribute1 = (col.hasOwnProperty('attribute1') && col.attribute1) ? attribute1 : '';
                            column.attribute2 = (col.hasOwnProperty('attribute2') && col.attribute2) ? attribute2 : '';
                            column.attribute3 = (col.hasOwnProperty('attribute3') && col.attribute3) ? attribute3 : '';
                            columns.push(column);
                        }
                    })
                }
                rowItem.columns = columns;

                this._records.push(rowItem);
            })
        }
    }

    connectedCallback() {

    }

    handleRecordClick(event) {

    }

    handleMenuClick(event) {
        this.dispatchEvent(new CustomEvent('menuclick', {
            detail: {
                id: event.detail.id,
                eventName: event.detail.eventName
            }
        }));
    }

    handleRecordSelect(event) {
        this.dispatchEvent(new CustomEvent('select', {
            detail: {
                record: event.detail.record
            }
        }));
    }

    handleEdit(event){
        this.dispatchEvent(new CustomEvent('edit',{
            detail: {
                recordId: event.detail.recordId
            }
        }));
    }

    handleCheckboxChange(event) {
        this.dispatchEvent(new CustomEvent('checkboxchange', {
            detail: {
                id: event.detail.id,
                checked: event.detail.checked
            }
        }));
    }
}