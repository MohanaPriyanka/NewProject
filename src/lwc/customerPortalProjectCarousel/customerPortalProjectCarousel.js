/*
 * Created by rebeccanachison on 9/27/21.
 */

import {LightningElement, wire, track} from 'lwc';
import { ShowToastEvent } from "lightning/platformShowToastEvent";
import fallbackImage from '@salesforce/label/c.Company_Default_Farm_Image';
import getUserSharedSolarSystems from '@salesforce/apex/CustomerPortalProjectCarouselController.getUserSharedSolarSystems';

export default class CustomerPortalProjectCarousel extends LightningElement {

    error;
    solarProjects;
    @track showModal;
    @track isLoading = true;

    @wire(getUserSharedSolarSystems) solarProjectResults(result) {
        if (result.data) {
            this.solarProjects = result.data.map(row=> {
                return {...row, projectJSON: JSON.stringify(row)};
            });
            this.isLoading = false;
        } else if (result.error) {
            this.error = result.error;
            this.isLoading = false;
            this.handleShowError();
        }
    }

    label = {
        fallbackImage
    }

    handleOpenModal(event) {
        this.selectedProject = JSON.parse(event.currentTarget.getAttribute('data-current'));
        this.showModal = true;
    }

    onCloseModal(event) {
        console.log(event.detail);
        this.showModal = event.detail.showModal;
    }

    handleShowError() {
        const event = new ShowToastEvent({
            title: 'Error',
            variant: 'error',
            message: this.error.body.message
        });
        this.dispatchEvent(event);
    }

}