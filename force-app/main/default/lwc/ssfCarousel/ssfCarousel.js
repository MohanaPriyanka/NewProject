/**
 * Created by LindsayHolmes_GearsCRM on 7/6/2020.
 */

import { LightningElement, api, track } from 'lwc';
import { loadStyle } from 'lightning/platformResourceLoader';
import staticResourceFolder from '@salesforce/resourceUrl/SimpleSignupFormStyling';

export default class CarouselComponent extends LightningElement {

    @api items;
    @api intervalSeconds;
    @track components;
    activeComponent = 0;
    loaded = false;
    intervalVar;

    connectedCallback() {
        loadStyle(this, staticResourceFolder + '/StyleLibrary.css');
    }
    
    renderedCallback() {
        if(!this.loaded) {
            this.arrangeComponents();
            this.setIntervalVal();
            this.loaded = true;
        }
    }

    arrangeComponents() {
        let untrackedComponents = [];
        let iterator = 0;
        this.items.forEach(item => {
            let temp = { ...item };
            temp.id = iterator;
            temp.contentId = 'content-id-' + iterator;
            if(temp.href){
                temp.href='javascript:void(0);';
            }
            if (iterator === this.activeComponent) {
                temp.hidden = false;
                temp.tabindex = 0;
                temp.active = true;
                temp.contentClass = 'slds-carousel__panel';
            } else {
                temp.hidden = true;
                temp.tabindex = -1;
                temp.active = false;
                temp.contentClass = 'slds-carousel__panel panel-hide';
            }
            untrackedComponents.push(temp);
            iterator++;
        });
        this.components = untrackedComponents;
    }

    setIntervalVal() {
        this.intervalVar = setInterval(() => {
            if (this.activeComponent === (this.components.length - 1)) {
                this.activeComponent = 0;
            } else {
                this.activeComponent++;
            }
            this.arrangeComponents();
        }, this.intervalSeconds * 1000);
    }
}