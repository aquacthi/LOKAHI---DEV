/*
 * (Summary)    Token Flex Usage dashboard - Tokens used by product doughnut chart
 * (Copyright)  WWD
 * (Author)     kimdanbi
 * (Email)      kimdanbi@amazon.com

 * (Change Log)
 * Date       | Author                                   | Version | Comments
 * ------------------------------------------------------------------------------------------------
 * 2022-10-19 | kimdanbi                                 | 1.0     | Initial Design
 * 
 */

import { LightningElement, wire, track } from 'lwc';
import { loadScript } from 'lightning/platformResourceLoader';

import ChartJS from '@salesforce/resourceUrl/chartjs_v280';
import ChartjsPluginDataLabels2 from '@salesforce/resourceUrl/ChartjsPluginDataLabels';

import getTokensConsumedByProduct from '@salesforce/apex/TokenFlexDashboardController.getTokensConsumedByProduct';

export default class TokenFlexUsageTokensUsedByProductDoughnutChart extends LightningElement {
    @track datasets = []; 
    @track labels = []; 
    @track data = []; 
    @track color = []; 

    @track resultData  = true;
    @track spinner = true;

    @track isChartJsInitialized;
    @track chartConfiguration;

    colors = [
        'rgb(204, 255, 255)',
        'rgb(0, 255, 255)', 
        'rgb(204, 299, 255)',
        'rgb(102, 178, 255)',
        'rgb(0, 128, 255)',
        'rgb(209, 204, 255)',
        'rgb(102, 102, 255)',
        'rgb(204, 153, 255)',
        'rgb(153, 51, 255)',
        'rgb(255, 204, 255)'
    ];

    renderedCallback() {

        Promise.all([loadScript(this, ChartJS),
                     loadScript(this, ChartjsPluginDataLabels2)])
        .then(() => {
            this.isChartJsInitialized = true;
        })
        .catch(error => {
            console.log('Tokens By Product error => ', error);
        })

        if (this.isChartJsInitialized && this.template.querySelector('canvas.tokensUsedByProduct') && this.datasets) {
            this.Initializechart();
        }

    }
        
    Initializechart() {
        const ctx = this.template.querySelector('canvas.tokensUsedByProduct').getContext('2d');
        
        this.chartConfiguration = {
            type: 'doughnut',
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
                    title: 'Product Name'
                },                 
                plugins: {
                    datalabels: {
                        backgroundColor: function(context) {
                          return context.dataset.backgroundColor;
                        },
                        color: 'black',
                        display: function(context) {
                          var dataset = context.dataset;
                          var count = dataset.data.length;
                          var value = dataset.data[context.dataIndex];
                          return value > count * 1.5;
                        },
                        padding: 6,
                        // formatter: Math.round
                        formatter:function(value,context){
                            var v = Math.round(value).toString();
                            if (v.length > 3) {
                                return v.replace(v.slice(-3), 'k');
                            } else {
                                return value;
                            }
                        } 
                    }
                },   
                title: {
                    display: true,
                    text: "Sum of Tokens Consumed"
                },
            }
        }

        this.chart = new window.Chart(ctx, this.chartConfiguration);
    }

   
    @wire (getTokensConsumedByProduct) 
    wiredTokensConsumedByProduct({error, data}){
        this.spinner = true;      
        if (error) {
            this.error = error;
            console.log('error => ' + JSON.stringify(error));

            this.spinner = false;      
        } else {
            try {     
                if (this.isChartJsInitialized) {      
                    let i = 0;
                    let name;
                    for (var key in data) {  
                        name = 'Product Name';
                        this.labels.push(key);
                        this.data.push(data[key]);
                        this.color.push(this.colors[i]);  

                        i++;          
                    };

                    this.datasets.push({
                        label: name, 
                        data: this.data,
                        backgroundColor: this.color,
                        datalabels: {
                            anchor: 'center',
                            backgroundColor: null,
                            borderWidth: 0,
                            fontSize: 10
                        }
                    });

                    this.spinner = false; 
                        
                    if (name == undefined || !name) {
                        this.resultData = false;
                    } else {
                        this.resultData = true;
                    }
                }
            } catch (error) {
                console.error('Error in getting data', error);
                this.spinner = false;      
            }
        }       
    }
}