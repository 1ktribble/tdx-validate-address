import { LightningElement, api, wire } from 'lwc';
import { getRecord } from 'lightning/uiRecordApi';
import ACCOUNT_ADDRESS_STATUS from '@salesforce/schema/Account.AddressStatus__c';

export default class AddressValidationProgressBar extends LightningElement {
    @api recordId;
    
    @wire(getRecord, { recordId: '$recordId', fields: [ACCOUNT_ADDRESS_STATUS] })
    account;
    
    get addressStatus() {
        return this.account.data.fields.AddressStatus__c.value;
    }

}
