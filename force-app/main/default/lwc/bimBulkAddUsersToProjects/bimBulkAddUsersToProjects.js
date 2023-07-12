// https://marcoalmodova.medium.com/parsing-a-csv-file-using-a-lwc-e99cac1b7515
import { LightningElement, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import PARSER from '@salesforce/resourceUrl/papaparse';
import insertStagingRecords from "@salesforce/apex/BimBulkAddUsersToProjectsController.insertStagingRecords";  
import validateStagingRecords from "@salesforce/apex/BimBulkAddUsersToProjectsController.validateStagingRecords";  
import calloutStagingRecords from "@salesforce/apex/BimBulkAddUsersToProjectsController.calloutStagingRecords";  

export default class BimBulkAddUsersToProjects extends LightningElement {
    parserInitialized = false;
    loading = false;
    validateButtonDisabled = true;
    submitButtonDisabled = true;
    submitButtonClicked = false;
    hasValidationError = false;

    @track _rows;
    @track _results;
    @track _jobId;

    get columns() {
        const columns = [
            { label: 'Project Id', fieldName: 'Project Id' },
            { label: 'Email', fieldName: 'Email' },
            { label: 'Company Id', fieldName: 'Company Id' },
            { label: 'Role Ids', fieldName: 'Role Ids' },
            { label: 'Services', fieldName: 'Services' },
            { label: 'Accesses', fieldName: 'Accesses' }
        ];

        if (this.results.length) {
            columns.unshift({ 
                label: 'Row Number', fieldName: 'Row Number' 
            });
            columns.unshift({ 
                label: 'Validation Result', fieldName: 'Validation Result' 
            });

            if (this.hasValidationError == false && this.submitButtonClicked == false) {
                this.submitButtonDisabled = false;
            }
        }

        return columns;
    }

    // disply preview of csv file in lightning-datatable
    get rows() {
        if (this._rows) {
            return this._rows.map((item, index) => {
                item['Row Number'] = index + 1;
                if (this.results[index]) {
                    item['Validation Result'] = this.results[index]['Validation Result'];
                }
                return item;
            })
        }

        return [];
    }

    get results() {
        if (this._results) {
            return this._results.map(item => {
                const result = {};
                result['Validation Result'] = item['Validation Result'];
                result['Row Number'] = item['Row Number'];
                if (result['Validation Result'] !== undefined) {
                    this.hasValidationError = true;
                }
                return result;
            });
        }

        return [];
    }

    handleUpload(event) {
        this.resetValues();

        if (event.target.files.length > 0) {
            const file = event.target.files[0];
            this.loading = true;
            Papa.parse(file, {
                quoteChar : '"',
                header : 'true',
                skipEmptyLines : 'true',
                complete : (parseResponse) => {
                    this._rows = parseResponse.data;
                    insertStagingRecords({ rows : JSON.stringify(this._rows) })
                        .then(insertResponse => {
                            this._jobId = insertResponse;
                            this.loading = false;
                            this.validateButtonDisabled = false;
                            this.submitButtonDisabled = true;
                        })
                        .catch(error => {
                            this._jobId = undefined;
                            this.loading = false;
                            this.showErrorToast(error.body.message);
                        });
                },
                error : (error) => {
                    this.loading = false;
                    this.showErrorToast(error);
                }
            })
        }
    }

    handleValidate() {
        this.validateButtonDisabled = true;
        this.loading = true;

        validateStagingRecords({ jobId : this._jobId })
            .then(validateResponse => {
                this._results = validateResponse;
                this.loading = false;
            })
            .catch(error => {
                this.loading = false;
                this.showErrorToast(error.body.message);
            });
    }

    handleSubmit() {
        this.submitButtonDisabled = true;
        this.loading = true;
        this.submitButtonClicked = true;

        calloutStagingRecords({ jobId : this._jobId })
            .then(postResponse => {
                this.loading = false;
            })
            .catch(error => {
                this.loading = false;
                this.showErrorToast(error);
            });
    }

    resetValues() {
        this.parserInitialized = false;
        this.loading = false;
        this.validateButtonDisabled = true;
        this.submitButtonDisabled = true;
        this.submitButtonClicked = false;
        this.hasValidationError = false;

        this._rows = undefined;
        this._results = undefined;
        this._jobId = undefined;
    }

    showErrorToast(error) {
        const evt = new ShowToastEvent({
            title: 'Error',
            message: error,
            variant: 'error',
            mode: 'sticky'
        });
        this.dispatchEvent(evt);
    }

    renderedCallback() {
        if (!this.parserInitialized) {
            loadScript(this, PARSER)
                .then(() => {
                    this.parserInitialized = true;
                })
                .catch(error => console.error(error));
        }
    }
}