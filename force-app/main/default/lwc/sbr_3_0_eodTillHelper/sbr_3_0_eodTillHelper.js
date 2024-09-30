import insertEndOfDayTillRecords from '@salesforce/apex/Sbr_3_0_endOfDayTillController.insertEndOfDayTillRecords';
import insertTillDetailRecords from '@salesforce/apex/Sbr_3_0_endOfDayTillController.insertTillDetailRecords';
import insertTillNewDepositRecord from '@salesforce/apex/Sbr_3_0_endOfDayTillController.insertTillNewDepositRecord';
import insertTillROADetailRecord from '@salesforce/apex/Sbr_3_0_endOfDayTillController.insertTillROADetailRecord';
import insertcashInvoiceOrIntercompanyRecord from '@salesforce/apex/Sbr_3_0_endOfDayTillController.insertcashInvoiceOrIntercompanyRecord';
import getTillSummary from '@salesforce/apex/SBR_3_0_API_GetEodTillSummary.getTillSummary';
import USER_ID from '@salesforce/user/Id';
import { NavigationMixin } from 'lightning/navigation';
import { openTab } from 'lightning/platformWorkspaceApi';



export async function makeEodAPICalls(getTillSummaryNext, compoundKey) {
    console.log('getTillSummary res', getTillSummaryNext);
    const eodTillId = await insertEndOfDayTillRecords({ eodString: JSON.stringify(getTillSummaryNext?.data || getTillSummaryNext), compoundKey });
    console.log('insertedRecId ', eodTillId)
    const tillDetailId = await insertTillDetailRecords({ eodTillId: eodTillId });
    console.log('tillDetailId ', tillDetailId);
    const [getNewDepositsResponse, getAdditionalDepositsResponse] = await Promise.all([
        getTillSummary({ tillDate: this.selectedDate, userId: USER_ID, sourceName: 'NewDeposits' }),
        getTillSummary({ tillDate: this.selectedDate, userId: USER_ID, sourceName: 'AdditionalDeposits' })
    ]);
    console.log('getNewDepositsResponse', [getNewDepositsResponse, getAdditionalDepositsResponse])
    Promise.all([insertTillNewDepositRecord({ depositString: JSON.stringify(getNewDepositsResponse?.data), tillDetailId, recordTypeName: 'New Deposit' }),
    insertTillNewDepositRecord({ depositString: JSON.stringify(getAdditionalDepositsResponse?.data), tillDetailId, recordTypeName: 'Additional Deposit' })
    ]); //FRONT-32190 added recordtype parameter
    const getCashROAControlResponse = await getTillSummary({ tillDate: this.selectedDate, userId: USER_ID, sourceName: 'CashROA' });
    console.log('getCashROAControlResponse ', getCashROAControlResponse);
    insertTillROADetailRecord({ tillROADetailString: JSON.stringify(getCashROAControlResponse?.data), tillDetailId });
    const [getCashInvoiceResponse, getInterCompanyDetailsResponse] = await Promise.all([
        getTillSummary({ tillDate: this.selectedDate, userId: USER_ID, sourceName: 'CashInvoice' }),
        getTillSummary({ tillDate: this.selectedDate, userId: USER_ID, sourceName: 'InterCompanyDetails' })
    ]);
    console.log('getCashInvoiceResponse', [getCashInvoiceResponse.data, getInterCompanyDetailsResponse.data]);
    Promise.all([insertcashInvoiceOrIntercompanyRecord({ tillRecordString: JSON.stringify(getCashInvoiceResponse?.data), tillDetailId, recordTypeName: 'Invoice' }),
    insertcashInvoiceOrIntercompanyRecord({ tillRecordString: JSON.stringify(getInterCompanyDetailsResponse?.data), tillDetailId, recordTypeName: 'InterCompany' })
    ]); //FRONT-32190 added recordtype parameter
    return { eodTillId, tillDetailId }
}

export async function openTabForSubmittedRecord(inputValues, eodTillId) {
    const pageReference = {
        type: 'standard__navItemPage',
        attributes: {
            recordId: eodTillId,
            apiName: 'EndOfDayTill',
            actionName: 'view'
        },
        state: inputValues
    };
    await this[NavigationMixin.Navigate](pageReference);
    await openTab({
        pageReference: {
            type: 'standard__navItemPage',
            attributes: {
                recordId: eodTillId,
                apiName: 'EndOfDayTill',
                actionName: 'view'
            },
            state: inputValues
        },

        icon: 'utility:currency',
        focus: true,
        label: '\u00A0\u00A0End of Day Till'
    });
}

export async function openTabForDraftRecord(inputValues) {
    const pageReference = {
        type: 'standard__navItemPage',
        attributes: {
            apiName: 'EndOfDayTill'
        },
        state: inputValues
    };
    await this[NavigationMixin.Navigate](pageReference);

   const randomNumber = Math.random();
   await openTab({
        pageReference: {
            type: 'standard__navItemPage',
            attributes: {
                apiName: 'EndOfDayTill'
            },
            state: inputValues
        },

        icon: 'utility:currency',
        focus: true,
        label: '\u00A0\u00A0End of Day Till'
    });
}

export async function getInputValues(eodTillId, tillDetailId, getTillSummaryNext) {
    return {
        c__selecteddate: this.selectedDate,
        c__eodTillRecordId: eodTillId,
        c__tillDetailId: tillDetailId,
        c__branchLocationNumber: this.branchLocationNumber,
        c__branchCompanyId: this.branchCompanyId,
        c__getTillSummaryResponse: encodeURIComponent(JSON.stringify(getTillSummaryNext?.data || getTillSummaryNext))
    }
}

export async function closeTab() {
    const { tabId } = await getFocusedTabInfo();
    await closeTab(tabId);
}

export function formatValueWithCurrencySign(value) {
    return new Intl.NumberFormat('en-US', {
        style: 'currency',
        currency: 'USD'
    }).format(value);
}

export function formatDate(dateStr) {
    if(!dateStr) return
    const [year, month, day] = dateStr.split('-');
    return `${month.padStart(2, '0')}/${day.padStart(2, '0')}/${year}`;
}