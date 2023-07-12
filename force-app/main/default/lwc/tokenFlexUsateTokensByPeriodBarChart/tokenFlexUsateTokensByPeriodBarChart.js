/*
 * (Summary)    Token Flex Usage dashboard - Tokens By period bar chart
 * (Copyright)  WWD
 * (Author)     kimdanbi
 * (Email)      kimdanbi@amazon.com

 * (Change Log)
 * Date       | Author                                   | Version | Comments
 * ------------------------------------------------------------------------------------------------
 * 2022-10-23 | kimdanbi                                 | 1.0     | Initial Design
 * 
 */

import { LightningElement, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';

import ChartJS from '@salesforce/resourceUrl/chartjs_v280';
import ChartjsPluginDataLabels from '@salesforce/resourceUrl/ChartjsPluginDataLabels';

import getTokensConsumedByPeriod from '@salesforce/apex/TokenFlexDashboardController.getTokensConsumedByPeriod';

export default class TokenFlexUsateTokensByPeriodBarChart extends LightningElement {
    
    @track resultData = true;

    @track spinner = true;
    @track isChartJsInitialized;
    @track datasets = [];    
    @track chartConfiguration;
    
    labels = [];
    colors = [
        'rgb(0, 0, 204)',
        'rgb(102, 102, 255)', 
        'rgb(102, 178, 255)',
        'rgb(51, 255, 153)',
        'rgb(0, 128, 255)',
        'rgb(209, 204, 255)',
        'rgb(102, 102, 255)',
        'rgb(204, 153, 255)',
        'rgb(153, 51, 255)',
        'rgb(255, 204, 255)'
    ];

    firstUsageDate;


    
    connectedCallback() {
        let currentDate = new Date();

        let currentYear = currentDate.getFullYear();
        let currentMonth = currentDate.getMonth();

        for (let i = 11; i >= 0; i--) {
            let tempDate = new Date(currentYear, currentMonth - i, 1);

            let month = tempDate.getMonth() + 1;
            let year = tempDate.getFullYear();

            month = month >= 10 ? month : '0' + month;

            this.labels.push((year + '-' + month));

            if (i === 11) {
                this.firstUsageDate = year + '-' + month;
            }
        }
    }

    renderedCallback() {

        Promise.all([loadScript(this, ChartJS),
                     loadScript(this, ChartjsPluginDataLabels)])
            .then(() => {
                this.isChartJsInitialized = true;
            })
            .catch(error => {
                console.log('Tokens By Period error => ', error);
            });

            if (this.isChartJsInitialized && this.template.querySelector('canvas.tokensByPeriod') && this.datasets) {
                this.Initializechart();
            }
    }

    Initializechart() {
        const ctx = this.template.querySelector('canvas.tokensByPeriod').getContext('2d');

        this.chartConfiguration = {
            type: 'bar',
            data: {
                labels: this.labels,
                datasets: this.datasets,                     
            },
            plugins: [ChartDataLabels],
            options: {                        
                responsive: true, 
                legend: {
                    display: true,
                    position: 'right',
                    title: 'Cost Center'
                }, 
                plugins: {
                    datalabels: {
                        formatter:function(value,context){
                            if (value == 0) {
                                return '';
                            } else {
                                var v = Math.round(value).toString();
                                if (v.length > 3) {
                                    return v.replace(v.slice(-3), 'k');
                                } else {
                                    return value;
                                }
                            }
                        }                
                    }
                },              
                scales: {
                    yAxes: [{
                        display: true,
                        ticks: {
                            beginAtZero: true,
                        },
                        scaleLabel: {
                            display: true,
                            labelString: 'Number of Tokens Used'
                        }
                    }],
                    xAxes: [{
                        display: true,
                        scaleLabel: {
                            display: true,
                                labelString: 'Date'
                        }
                    }]
                }
            },
        };

        this.chart = new window.Chart(ctx, this.chartConfiguration);
    }

    @wire (getTokensConsumedByPeriod, {period: "$firstUsageDate"}) 
    wiredTokensConsumedByPeriod({error, data}){
        this.spinner = true;
        if (error) {
            this.error = error;
            console.log('error => ' + JSON.stringify(error));

            this.spinner = false;

        } else {
            try {
                if (this.isChartJsInitialized) {
                    let i = 1;

                    for (var costCenter in data) {          
                        let datas = [];
                        let backgroundColor = [];  

                        for (var month in this.labels) {    
                            let consumed;

                            for (var value in data[costCenter]) {                                                
                                if (this.labels[month] === value) {
                                    consumed = data[costCenter][value];
                                    break;

                                } else {
                                    consumed = 0;
                                }                            
                            }     

                            datas.push(consumed); 
                            backgroundColor.push(this.colors[i]);
                        }                   
                        
                        i++;
                    
                        this.datasets.push({
                            label: costCenter, 
                            data: datas,
                            backgroundColor: backgroundColor,
                            datalabels:{
                                color: 'black',
                                align: 'top',
                                anchor: 'end',
                                offset: 0,
                            }
                        });
                    };  
                    this.spinner = false;

                    if (this.datasets.length == 0 || !this.datasets) {
                        this.resultData = false;
                    } else {
                        this.resultData = true;
                    }
                }
            } catch (error) {
                console.log(error);
                this.spinner = false;
            }
        }       
    }    
}